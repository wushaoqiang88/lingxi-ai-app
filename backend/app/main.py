from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from .ai_gateway import configured_provider_summary, generate_companion_voice_result, generate_document_result, generate_module_result, generate_tts_result
from .doc_generator import OUTPUT_DIR, detect_doc_type
from .fallbacks import fallback_result
from .modules import MODULES, MODULE_BY_ID

app = FastAPI(title="Lingxi AI Super App API", version="0.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ModuleRequest(BaseModel):
    text: str = ""
    mode: str = "default"
    payload: dict[str, Any] = Field(default_factory=dict)


class VoiceRequest(BaseModel):
    audio_base64: str
    format: str = "m4a"
    payload: dict[str, Any] = Field(default_factory=dict)


def split_ai_content(content: str, module_id: str | None = None) -> list[str]:
    text = content.strip()
    if not text:
        return []
    # 陪伴类模块保持原始口语化表达，不强行切段
    if module_id in {"companion", "avatar", "treehole", "study", "car_radio"}:
        return [text]
    parts = [part.strip() for part in text.split("\n\n") if part.strip()]
    if not parts:
        parts = [text]
    return parts[:6]


async def build_result(module_id: str, request: ModuleRequest) -> dict[str, Any]:
    module = MODULE_BY_ID[module_id]
    text = request.text.strip() or "我想体验这个 AI 功能"

    # ── car_radio: TTS with qwen-omni (text + audio) ──
    if module_id == "car_radio":
        from .prompts import SYSTEM_PROMPTS
        channel = request.payload.get("channel", "commute")
        prompt_key = f"car_radio_{channel}"
        system_prompt = SYSTEM_PROMPTS.get(prompt_key, SYSTEM_PROMPTS["car_radio_commute"])
        if request.payload.get("locale") == "en":
            system_prompt += "\n\nPlease answer in natural, concise English."
        ai_result = await generate_tts_result(system_prompt, text)
        result = [ai_result["content"]] if ai_result["content"] else fallback_result(module_id)
        tips = ["支持语音播放", "支持复制"]
        if ai_result["source"] == "fallback":
            tips.append("语音合成暂不可用，已使用本地兜底结果")
        return {
            "module": module,
            "input": text,
            "mode": request.mode,
            "source": ai_result["source"],
            "provider": ai_result["provider"],
            "model": ai_result["model"],
            "result": result,
            "images": [],
            "audio_base64": ai_result.get("audio_base64", ""),
            "audio_format": ai_result.get("audio_format", "m4a"),
            "files": [],
            "tips": tips,
            "usage": ai_result.get("usage", {}),
            "error": ai_result.get("error"),
            "created_at": datetime.now(UTC).isoformat(),
        }

    # ── office_doc: detect document type and generate real file ──
    if module_id == "office_doc":
        doc_type = detect_doc_type(text)
        if doc_type:
            doc_result = await generate_document_result(doc_type, text, request.payload)
            summary_lines = []
            if doc_result.get("doc_file"):
                ext_label = {"pptx": "PPT", "pdf": "PDF", "xlsx": "Excel"}.get(doc_type, doc_type)
                summary_lines.append(f"✅ 已生成 {ext_label} 文件：{doc_result['doc_file']}")
                summary_lines.append("点击下方按钮下载文件。")
            if doc_result.get("error"):
                summary_lines.append(f"⚠️ {doc_result['error']}")
            if not summary_lines:
                summary_lines.append("文档生成完成。")
            tips = ["支持下载真实文件"]
            if doc_result.get("doc_file"):
                tips.append(f"文件格式：{doc_type.upper()}")
            return {
                "module": module,
                "input": text,
                "mode": request.mode,
                "source": doc_result.get("source", "ai"),
                "provider": doc_result.get("provider", ""),
                "model": doc_result.get("model", ""),
                "result": summary_lines,
                "images": [],
                "files": [{"name": doc_result["doc_file"], "type": doc_type,
                           "url": f"/api/docs/download/{doc_result['doc_file']}"}]
                         if doc_result.get("doc_file") else [],
                "tips": tips,
                "usage": doc_result.get("usage", {}),
                "error": doc_result.get("error"),
                "created_at": datetime.now(UTC).isoformat(),
            }

    ai_result = await generate_module_result(module_id, text, request.payload)
    result = split_ai_content(ai_result["content"], module_id) if ai_result["source"] == "ai" else fallback_result(module_id)
    tips = ["支持复制", "可生成分享卡片"]
    if ai_result["source"] == "fallback":
        tips.append("当前使用本地兜底结果：请检查 API Key 或模型服务")
    if ai_result.get("images"):
        tips.append("已生成真实 AI 图片，图片链接 24 小时内有效，请及时保存")
    elif ai_result.get("error") and module_id in {"image_fix", "dressup"}:
        tips.append(f"图片生成失败：{ai_result['error']}")
    return {
        "module": module,
        "input": text,
        "mode": request.mode,
        "source": ai_result["source"],
        "provider": ai_result["provider"],
        "model": ai_result["model"],
        "result": result,
        "images": ai_result.get("images", []),
        "files": [],
        "tips": tips,
        "usage": ai_result.get("usage", {}),
        "error": ai_result.get("error"),
        "created_at": datetime.now(UTC).isoformat(),
    }


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "lingxi-ai",
        "time": datetime.now(UTC).isoformat(),
        "ai": configured_provider_summary(),
    }


@app.get("/api/modules")
def get_modules() -> dict[str, Any]:
    return {"modules": MODULES}


@app.get("/api/ai/provider")
def get_ai_provider() -> dict[str, Any]:
    return configured_provider_summary()


@app.post("/api/modules/{module_id}/run")
async def run_module(module_id: str, request: ModuleRequest) -> dict[str, Any]:
    if module_id not in MODULE_BY_ID:
        return {"error": "module_not_found", "message": "未知模块"}
    return await build_result(module_id, request)


@app.post("/api/modules/companion/voice")
async def run_companion_voice(request: VoiceRequest) -> dict[str, Any]:
    module = MODULE_BY_ID["companion"]
    ai_result = await generate_companion_voice_result(request.audio_base64, request.format, request.payload)
    result = split_ai_content(ai_result["content"], "companion") if ai_result["source"] == "ai" else fallback_result("companion")
    tips = ["支持短期记忆", "语音输入由 Qwen-Omni 理解"]
    if ai_result["source"] == "fallback":
        tips.append("语音模型暂不可用，已使用本地兜底结果")
    return {
        "module": module,
        "input": "语音消息",
        "mode": "voice",
        "source": ai_result["source"],
        "provider": ai_result["provider"],
        "model": ai_result["model"],
        "result": result,
        "images": [],
        "audio_base64": ai_result.get("audio_base64", ""),
        "audio_format": ai_result.get("audio_format", "wav"),
        "files": [],
        "tips": tips,
        "usage": ai_result.get("usage", {}),
        "error": ai_result.get("error"),
        "created_at": datetime.now(UTC).isoformat(),
    }


MIME_TYPES = {
    ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ".pdf": "application/pdf",
    ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
}


@app.get("/api/docs/download/{filename}")
def download_doc(filename: str) -> FileResponse:
    # Sanitize: only allow files in OUTPUT_DIR, no path traversal
    safe_name = Path(filename).name
    file_path = OUTPUT_DIR / safe_name
    if not file_path.exists() or not file_path.is_file():
        from fastapi.responses import JSONResponse
        return JSONResponse(status_code=404, content={"error": "file_not_found"})
    suffix = file_path.suffix.lower()
    media_type = MIME_TYPES.get(suffix, "application/octet-stream")
    return FileResponse(
        path=str(file_path),
        media_type=media_type,
        filename=safe_name,
    )


@app.post("/api/intent")
def route_intent(request: ModuleRequest) -> dict[str, Any]:
    text = request.text.lower()
    rules = [
        ("resume", ["简历", "jd", "面试", "求职"]),
        ("study", ["题", "作业", "数学", "作文"]),
        ("image_fix", ["修图", "照片", "证件照", "背景"]),
        ("writing", ["文案", "小红书", "朋友圈", "周报", "写"]),
        ("brainhole", ["脑洞", "创意", "灵感", "如果", "点子"]),
        ("companion", ["难受", "焦虑", "陪", "聊天"]),
        ("career", ["职业", "转行", "方向"]),
        ("avatar", ["代回", "回复", "像我"]),
        ("treehole", ["树洞", "匿名", "倾诉"]),
        ("dressup", ["穿搭", "换装", "衣服"]),
        ("knowledge", ["为什么", "是什么", "知识"]),
    ]
    for module_id, keywords in rules:
        if any(keyword in text for keyword in keywords):
            return {"module_id": module_id, "confidence": 0.92, "module": MODULE_BY_ID[module_id]}
    return {"module_id": "writing", "confidence": 0.62, "module": MODULE_BY_ID["writing"]}
