import base64
import io
import os
import logging
import json
import subprocess
import tempfile
import wave
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import httpx
from dotenv import load_dotenv

from .doc_generator import detect_doc_type, generate_document, get_doc_system_prompt, parse_ai_json
from .prompts import build_messages, build_vision_messages

load_dotenv(Path(__file__).resolve().parents[1] / ".env")


@dataclass(frozen=True)
class ProviderConfig:
    provider: str
    base_url: str
    model: str
    api_key: str | None
    temperature: float
    timeout_seconds: float


PROVIDERS = {
    "deepseek": {
        "base_url": "https://api.deepseek.com/v1",
        "model": "deepseek-chat",
        "key_env": "DEEPSEEK_API_KEY",
        "model_env": "DEEPSEEK_MODEL",
    },
    "qwen": {
        "base_url": "https://dashscope.aliyuncs.com/compatible-mode/v1",
        "model": "qwen-plus",
        "key_env": "QWEN_API_KEY",
        "model_env": "QWEN_MODEL",
    },
    "glm": {
        "base_url": "https://open.bigmodel.cn/api/paas/v4",
        "model": "glm-4-flash",
        "key_env": "GLM_API_KEY",
        "model_env": "GLM_MODEL",
    },
    "kimi": {
        "base_url": "https://api.moonshot.cn/v1",
        "model": "moonshot-v1-8k",
        "key_env": "KIMI_API_KEY",
        "model_env": "KIMI_MODEL",
    },
    "siliconflow": {
        "base_url": "https://api.siliconflow.cn/v1",
        "model": "deepseek-ai/DeepSeek-V3",
        "key_env": "SILICONFLOW_API_KEY",
        "model_env": "SILICONFLOW_MODEL",
    },
    "openai": {
        "base_url": "https://api.openai.com/v1",
        "model": "gpt-4o-mini",
        "key_env": "OPENAI_API_KEY",
        "model_env": "OPENAI_MODEL",
    },
}


def get_provider_config() -> ProviderConfig:
    provider = os.getenv("AI_PROVIDER", "deepseek").strip().lower()
    preset = PROVIDERS.get(provider, PROVIDERS["deepseek"])
    base_url = os.getenv("AI_BASE_URL") or preset["base_url"]
    model = os.getenv("AI_MODEL") or os.getenv(preset["model_env"]) or preset["model"]
    api_key = os.getenv("AI_API_KEY") or os.getenv(preset["key_env"])
    temperature = float(os.getenv("AI_TEMPERATURE", "0.75"))
    timeout_seconds = float(os.getenv("AI_TIMEOUT_SECONDS", "60"))
    return ProviderConfig(
        provider=provider,
        base_url=base_url.rstrip("/"),
        model=model,
        api_key=api_key,
        temperature=temperature,
        timeout_seconds=timeout_seconds,
    )


def configured_provider_summary() -> dict[str, Any]:
    config = get_provider_config()
    return {
        "provider": config.provider,
        "base_url": config.base_url,
        "model": config.model,
        "image_model": os.getenv("WANX_IMAGE_MODEL", "wan2.7-image"),
        "has_api_key": bool(config.api_key),
    }


def get_model_for_request(config: ProviderConfig, module_id: str, attachment: dict[str, Any]) -> str:
    if attachment.get("attachment_type") == "image" and module_id in {"image_fix", "dressup", "study"}:
        return os.getenv("AI_VISION_MODEL") or os.getenv("QWEN_VISION_MODEL") or "qwen-vl-max"
    return config.model


def should_generate_image(module_id: str, attachment: dict[str, Any]) -> bool:
    return module_id in {"image_fix", "dressup"} and attachment.get("attachment_type") == "image" and bool(attachment.get("base64"))


def build_image_edit_prompt(module_id: str, user_text: str) -> str:
    request = user_text.strip() or "请根据当前模块生成高质量图片结果。"
    if module_id == "dressup":
        return (
            "请基于用户上传的人像进行真实虚拟试衣图像编辑。"
            "保持人物身份、人脸特征、姿态、背景和构图尽量一致，只替换服装与整体穿搭质感。"
            "服装必须自然贴合人体，避免畸形肢体、错位衣领、过度磨皮、文字水印。"
            f"用户需求：{request}"
        )
    return (
        "请基于用户上传的图片进行真实图像编辑。"
        "根据用户需求调整画面，但保持主体身份与构图自然可信。"
        "避免过饱和、偏色、畸形、文字水印和明显 AI 痕迹。"
        f"用户需求：{request}"
    )


def extract_image_urls(data: dict[str, Any]) -> list[str]:
    urls: list[str] = []
    for choice in data.get("output", {}).get("choices", []):
        content_items = choice.get("message", {}).get("content", [])
        for item in content_items:
            image_url = item.get("image") if isinstance(item, dict) else None
            if image_url:
                urls.append(image_url)
    return urls


async def generate_image_urls(module_id: str, user_text: str, attachment: dict[str, Any], config: ProviderConfig) -> list[str]:
    image_base64 = attachment.get("base64") or ""
    mime_type = attachment.get("mime_type") or "image/jpeg"
    api_key = os.getenv("DASHSCOPE_API_KEY") or os.getenv("QWEN_API_KEY") or config.api_key
    if not api_key:
        raise RuntimeError("missing_image_api_key")
    endpoint = os.getenv(
        "WANX_IMAGE_ENDPOINT",
        "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation",
    )
    payload = {
        "model": os.getenv("WANX_IMAGE_MODEL", "wan2.7-image"),
        "input": {
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"text": build_image_edit_prompt(module_id, user_text)},
                        {"image": f"data:{mime_type};base64,{image_base64}"},
                    ],
                }
            ]
        },
        "parameters": {
            "size": os.getenv("WANX_IMAGE_SIZE", "2K"),
            "n": 1,
            "watermark": False,
        },
    }
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    timeout = httpx.Timeout(float(os.getenv("AI_IMAGE_TIMEOUT_SECONDS", "180")))
    async with httpx.AsyncClient(timeout=timeout) as client:
        response = await client.post(endpoint, headers=headers, json=payload)
        response.raise_for_status()
        data = response.json()
    image_urls = extract_image_urls(data)
    if not image_urls:
        raise RuntimeError(f"image_generation_empty_result: {data}")
    return image_urls


async def generate_module_result(module_id: str, user_text: str, attachment: dict[str, Any] | None = None) -> dict[str, Any]:
    config = get_provider_config()
    attachment = attachment or {}
    if not config.api_key:
        return {
            "source": "fallback",
            "provider": config.provider,
            "model": config.model,
            "content": "",
            "error": "missing_api_key",
        }

    model = get_model_for_request(config, module_id, attachment)
    messages = build_vision_messages(module_id, user_text, attachment) if attachment.get("attachment_type") == "image" else build_messages(module_id, user_text, attachment)
    # 陪伴类模块用更高温度，让回应更像真人朋友
    temperature = config.temperature
    if module_id in {"companion", "avatar", "treehole"}:
        temperature = max(temperature, 0.95)
    payload = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
    }
    headers = {
        "Authorization": f"Bearer {config.api_key}",
        "Content-Type": "application/json",
    }
    timeout_sec = config.timeout_seconds
    if attachment.get("attachment_type") == "image":
        timeout_sec = max(timeout_sec, 120)

    models_to_try = [model]
    if module_id == "study" and attachment.get("attachment_type") == "image" and model == "qwen-vl-max":
        models_to_try.append("qwen-vl-plus")

    last_error = ""
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(timeout_sec)) as client:
            for current_model in models_to_try:
                payload["model"] = current_model
                try:
                    response = await client.post(
                        f"{config.base_url}/chat/completions",
                        headers=headers,
                        json=payload,
                    )
                    response.raise_for_status()
                    data = response.json()
                    content = data["choices"][0]["message"]["content"]
                    usage = data.get("usage", {})
                    image_urls: list[str] = []
                    image_error = None
                    if should_generate_image(module_id, attachment):
                        try:
                            image_urls = await generate_image_urls(module_id, user_text, attachment, config)
                        except Exception as image_exc:
                            image_error = str(image_exc)
                    return {
                        "source": "ai",
                        "provider": config.provider,
                        "model": current_model,
                        "content": content.strip(),
                        "images": image_urls,
                        "usage": usage,
                        "error": image_error,
                    }
                except httpx.HTTPStatusError as exc:
                    last_error = f"HTTP {exc.response.status_code}: {exc.response.text}"
                    logging.error(
                        "AI call failed for module=%s model=%s: %s",
                        module_id,
                        current_model,
                        last_error[:500],
                    )
                except httpx.ReadTimeout as exc:
                    last_error = repr(exc)
                    logging.error("AI call timeout for module=%s model=%s", module_id, current_model, exc_info=True)

        return {
            "source": "fallback",
            "provider": config.provider,
            "model": models_to_try[-1],
            "content": "",
            "error": last_error,
        }
    except Exception as exc:
        logging.error("AI call exception for module=%s model=%s: %r", module_id, model, exc, exc_info=True)
        return {
            "source": "fallback",
            "provider": config.provider,
            "model": model,
            "content": "",
            "error": str(exc),
        }


async def generate_companion_voice_result(audio_base64: str, audio_format: str, payload_data: dict[str, Any] | None = None) -> dict[str, Any]:
    config = get_provider_config()
    payload_data = payload_data or {}
    if not config.api_key:
        return {
            "source": "fallback",
            "provider": config.provider,
            "model": "qwen3.5-omni-plus",
            "content": "",
            "error": "missing_api_key",
        }

    history_items = payload_data.get("conversation_history") or []
    history_lines: list[str] = []
    if isinstance(history_items, list):
        for item in history_items[-20:]:
            if not isinstance(item, dict):
                continue
            role = item.get("role")
            content = str(item.get("content") or "").strip()
            if role not in {"user", "assistant"} or not content:
                continue
            name = "用户" if role == "user" else "你"
            history_lines.append(f"{name}: {content[:300]}")
    history_text = "\n".join(history_lines)
    prompt = (
        "你是用户的真人朋友式陪伴聊天对象。请先听懂语音内容，再自然回应。"
        "回答要短句、口语化、有共情，不要像客服，不要列条目。"
    )
    if history_text:
        prompt += f"\n最近聊天记录：\n{history_text}"

    request_body = {
        "model": os.getenv("QWEN_OMNI_MODEL", "qwen3.5-omni-plus"),
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_audio",
                        "input_audio": {
                            "data": f"data:audio/{audio_format};base64,{audio_base64}",
                            "format": audio_format,
                        },
                    },
                    {"type": "text", "text": prompt},
                ],
            }
        ],
        "modalities": ["text", "audio"],
        "audio": {"voice": os.getenv("QWEN_OMNI_VOICE", "Tina"), "format": "mp3"},
        "stream": True,
        "stream_options": {"include_usage": True},
    }
    headers = {
        "Authorization": f"Bearer {config.api_key}",
        "Content-Type": "application/json",
    }

    try:
        text_parts: list[str] = []
        transcript_parts: list[str] = []
        audio_parts: list[str] = []
        usage: dict[str, Any] = {}
        async with httpx.AsyncClient(timeout=httpx.Timeout(max(config.timeout_seconds, 120))) as client:
            async with client.stream(
                "POST",
                f"{config.base_url}/chat/completions",
                headers=headers,
                json=request_body,
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if not line.startswith("data:"):
                        continue
                    data_text = line.removeprefix("data:").strip()
                    if not data_text or data_text == "[DONE]":
                        continue
                    data = json.loads(data_text)
                    if data.get("usage"):
                        usage = data["usage"]
                    for choice in data.get("choices", []):
                        delta = choice.get("delta") or {}
                        if delta.get("content"):
                            text_parts.append(delta["content"])
                        audio = delta.get("audio")
                        if isinstance(audio, dict):
                            if audio.get("transcript"):
                                transcript_parts.append(audio["transcript"])
                            if audio.get("data"):
                                audio_parts.append(audio["data"])
        # 优先使用语音文字稿（和音频内容一致），回退到纯文本
        content = "".join(transcript_parts).strip() or "".join(text_parts).strip()
        # 逐块解码 base64 音频再合并，避免 padding 破坏拼接
        audio_raw = b"".join(base64.b64decode(chunk) for chunk in audio_parts)
        # Qwen-Omni 返回原始 PCM（24kHz 16bit 单声道）
        # 先封装为 WAV，再用 ffmpeg 压缩为 AAC(.m4a) 减小体积
        audio_b64 = ""
        audio_fmt = "m4a"
        if audio_raw:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as wf_tmp:
                wav_path = wf_tmp.name
                with wave.open(wf_tmp, "wb") as wf:
                    wf.setnchannels(1)
                    wf.setsampwidth(2)
                    wf.setframerate(24000)
                    wf.writeframes(audio_raw)
            m4a_path = wav_path.replace(".wav", ".m4a")
            try:
                ffmpeg_bin = os.getenv("FFMPEG_PATH", "/opt/homebrew/bin/ffmpeg")
                subprocess.run(
                    [ffmpeg_bin, "-y", "-i", wav_path, "-c:a", "aac", "-b:a", "64k", m4a_path],
                    capture_output=True, timeout=30, check=True,
                )
                with open(m4a_path, "rb") as f:
                    audio_b64 = base64.b64encode(f.read()).decode()
            except Exception:
                # ffmpeg 失败则回退为 WAV
                logging.warning("ffmpeg AAC encoding failed, falling back to WAV")
                with open(wav_path, "rb") as f:
                    audio_b64 = base64.b64encode(f.read()).decode()
                audio_fmt = "wav"
            finally:
                for p in (wav_path, m4a_path):
                    try:
                        os.unlink(p)
                    except OSError:
                        pass
        return {
            "source": "ai" if content else "fallback",
            "provider": config.provider,
            "model": request_body["model"],
            "content": content,
            "images": [],
            "audio_base64": audio_b64,
            "audio_format": audio_fmt,
            "usage": usage,
            "error": None if content else "empty_omni_response",
        }
    except httpx.HTTPStatusError as exc:
        error = f"HTTP {exc.response.status_code}: {exc.response.text}"
        logging.error("Companion voice call failed: %s", error[:500])
        return {
            "source": "fallback",
            "provider": config.provider,
            "model": request_body["model"],
            "content": "",
            "error": error,
        }
    except Exception as exc:
        logging.error("Companion voice call exception: %r", exc, exc_info=True)
        return {
            "source": "fallback",
            "provider": config.provider,
            "model": request_body["model"],
            "content": "",
            "error": str(exc),
        }


async def generate_document_result(
    doc_type: str, user_text: str, attachment: dict[str, Any] | None = None
) -> dict[str, Any]:
    """Call AI to get structured JSON, then generate a real document file."""
    config = get_provider_config()
    if not config.api_key:
        return {"source": "fallback", "provider": config.provider, "model": config.model,
                "content": "", "doc_file": None, "error": "missing_api_key"}

    system_prompt = get_doc_system_prompt(doc_type)
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_text or "请演示这个文档功能。"},
    ]
    payload = {
        "model": config.model,
        "messages": messages,
        "temperature": 0.5,
    }
    headers = {
        "Authorization": f"Bearer {config.api_key}",
        "Content-Type": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(config.timeout_seconds)) as client:
            response = await client.post(
                f"{config.base_url}/chat/completions",
                headers=headers,
                json=payload,
            )
            response.raise_for_status()
            data = response.json()
            raw_content = data["choices"][0]["message"]["content"].strip()
            usage = data.get("usage", {})

        doc_data = parse_ai_json(raw_content)
        doc_path = generate_document(doc_type, doc_data)

        return {
            "source": "ai",
            "provider": config.provider,
            "model": config.model,
            "content": raw_content,
            "doc_file": doc_path.name,
            "doc_type": doc_type,
            "usage": usage,
            "error": None,
        }
    except json.JSONDecodeError as exc:
        return {
            "source": "ai",
            "provider": config.provider,
            "model": config.model,
            "content": raw_content if "raw_content" in dir() else "",
            "doc_file": None,
            "doc_type": doc_type,
            "usage": {},
            "error": f"AI 返回的内容无法解析为 JSON：{exc}",
        }
    except Exception as exc:
        return {
            "source": "fallback",
            "provider": config.provider,
            "model": config.model,
            "content": "",
            "doc_file": None,
            "doc_type": doc_type,
            "usage": {},
            "error": str(exc),
        }


async def generate_tts_result(system_prompt: str, user_text: str) -> dict[str, Any]:
    """Generate text + audio using qwen-omni for car_radio TTS."""
    config = get_provider_config()
    if not config.api_key:
        return {
            "source": "fallback",
            "provider": config.provider,
            "model": "qwen3.5-omni-plus",
            "content": "",
            "audio_base64": "",
            "audio_format": "m4a",
            "error": "missing_api_key",
        }

    request_body = {
        "model": os.getenv("QWEN_OMNI_MODEL", "qwen3.5-omni-plus"),
        "messages": [
            {"role": "system", "content": [{"type": "text", "text": system_prompt}]},
            {"role": "user", "content": [{"type": "text", "text": user_text}]},
        ],
        "modalities": ["text", "audio"],
        "audio": {"voice": os.getenv("QWEN_RADIO_VOICE", "Tina"), "format": "mp3"},
        "stream": True,
        "stream_options": {"include_usage": True},
    }
    headers = {
        "Authorization": f"Bearer {config.api_key}",
        "Content-Type": "application/json",
    }

    try:
        text_parts: list[str] = []
        transcript_parts: list[str] = []
        audio_parts: list[str] = []
        usage: dict[str, Any] = {}
        async with httpx.AsyncClient(timeout=httpx.Timeout(max(config.timeout_seconds, 120))) as client:
            async with client.stream(
                "POST",
                f"{config.base_url}/chat/completions",
                headers=headers,
                json=request_body,
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if not line.startswith("data:"):
                        continue
                    data_text = line.removeprefix("data:").strip()
                    if not data_text or data_text == "[DONE]":
                        continue
                    data = json.loads(data_text)
                    if data.get("usage"):
                        usage = data["usage"]
                    for choice in data.get("choices", []):
                        delta = choice.get("delta") or {}
                        if delta.get("content"):
                            text_parts.append(delta["content"])
                        audio = delta.get("audio")
                        if isinstance(audio, dict):
                            if audio.get("transcript"):
                                transcript_parts.append(audio["transcript"])
                            if audio.get("data"):
                                audio_parts.append(audio["data"])

        content = "".join(transcript_parts).strip() or "".join(text_parts).strip()
        audio_raw = b"".join(base64.b64decode(chunk) for chunk in audio_parts)
        audio_b64 = ""
        audio_fmt = "m4a"
        if audio_raw:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as wf_tmp:
                wav_path = wf_tmp.name
                with wave.open(wf_tmp, "wb") as wf:
                    wf.setnchannels(1)
                    wf.setsampwidth(2)
                    wf.setframerate(24000)
                    wf.writeframes(audio_raw)
            m4a_path = wav_path.replace(".wav", ".m4a")
            try:
                ffmpeg_bin = os.getenv("FFMPEG_PATH", "/opt/homebrew/bin/ffmpeg")
                subprocess.run(
                    [ffmpeg_bin, "-y", "-i", wav_path, "-c:a", "aac", "-b:a", "64k", m4a_path],
                    capture_output=True, timeout=30, check=True,
                )
                with open(m4a_path, "rb") as f:
                    audio_b64 = base64.b64encode(f.read()).decode()
            except Exception:
                logging.warning("ffmpeg AAC encoding failed for TTS, falling back to WAV")
                with open(wav_path, "rb") as f:
                    audio_b64 = base64.b64encode(f.read()).decode()
                audio_fmt = "wav"
            finally:
                for p in (wav_path, m4a_path):
                    try:
                        os.unlink(p)
                    except OSError:
                        pass
        return {
            "source": "ai" if content else "fallback",
            "provider": config.provider,
            "model": request_body["model"],
            "content": content,
            "audio_base64": audio_b64,
            "audio_format": audio_fmt,
            "usage": usage,
            "error": None if content else "empty_tts_response",
        }
    except Exception as exc:
        logging.error("TTS generation failed: %r", exc, exc_info=True)
        return {
            "source": "fallback",
            "provider": config.provider,
            "model": "qwen3.5-omni-plus",
            "content": "",
            "audio_base64": "",
            "audio_format": "m4a",
            "error": str(exc),
        }
