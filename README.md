# 灵犀 AI 超级 App

一个集成 11 个 AI 能力模块的 Flutter + FastAPI 原型项目。

## 功能模块

- 陪伴：灵伴、分身、树洞
- 创作：妙笔、快文
- 影像：秒修、换装
- 学习：解题侠、知了
- 求职：职达、职画

## 输入能力与分享

| 模块 | 拍照 | 相册 | 文件导入 | 复制/分享 |
|---|---|---|---|---|
| 灵伴 | - | - | 支持 | 支持 |
| 分身 | - | - | 支持 | 支持 |
| 树洞 | - | - | 支持 | 支持 |
| 妙笔 | - | - | 支持 | 支持 |
| 快文 | - | - | 支持 | 支持 |
| 秒修 | 支持 | 支持 | - | 支持 |
| 换装 | 支持 | 支持 | - | 支持 |
| 解题侠 | 支持 | 支持 | 支持 | 支持 |
| 知了 | - | - | 支持 | 支持 |
| 职达 | - | - | 支持 | 支持 |
| 职画 | - | - | 支持 | 支持 |

结果区支持：

- 单段结果复制
- 一键复制全部
- 生成分享卡片弹窗
- 复制分享卡片文案
- 保存分享卡片 PNG 到相册

## 项目结构

```text
ai_super_app/     Flutter 前端
backend/          FastAPI 后端
*.md              产品与架构设计文档
```

## 环境

Flutter SDK 已安装在：

```bash
/Users/wushaoqiang/development/flutter
```

本项目使用 Flutter Web 进行快速联调。Android SDK 当前未安装，`flutter doctor` 会提示 Android toolchain 缺失，但不影响 Web/iOS/macOS 开发。

## 启动后端

后端会读取 `backend/.env`。该文件已被 `.gitignore` 忽略，不要提交到仓库。

当前默认供应商：通义千问（`AI_PROVIDER=qwen`）。

可选供应商：

| AI_PROVIDER | 默认模型 | 状态 |
|---|---|---|
| deepseek | deepseek-chat | 已接入，当前测试返回额度不足 |
| qwen | qwen-plus | 已接入，当前可用 |
| glm | glm-4-flash | 已接入，当前可用 |
| kimi | moonshot-v1-8k | 已接入，当前测试限流 |
| siliconflow | deepseek-ai/DeepSeek-V3 | 已接入，当前测试拒绝访问 |
| openai | gpt-4o-mini | 已接入，需自行配置 Key |

切换供应商：修改 `backend/.env` 中的 `AI_PROVIDER`，然后重启后端。

```bash
cd /Users/wushaoqiang/Desktop/app源码/游戏/backend
/Users/wushaoqiang/Desktop/app源码/游戏/.venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

健康检查：

```bash
curl http://127.0.0.1:8000/health
```

## 启动前端

```bash
cd /Users/wushaoqiang/Desktop/app源码/游戏/ai_super_app
export PATH="/Users/wushaoqiang/development/flutter/bin:$PATH"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

访问：

```text
http://127.0.0.1:5173
```

## iOS 真机调试

真机访问后端时不能使用 `127.0.0.1`，需要让后端监听局域网地址，并把 Mac 的局域网 IP 传给 Flutter。

在 Xcode 中调试或安装时，请打开：

```text
ai_super_app/ios/Runner.xcworkspace
```

不要直接打开 `Runner.xcodeproj`，否则 CocoaPods 插件不会被加载，可能出现 `Module 'file_picker' not found`。

```bash
cd /Users/wushaoqiang/Desktop/app源码/游戏/backend
/Users/wushaoqiang/Desktop/app源码/游戏/.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

```bash
ipconfig getifaddr en0
```

```bash
cd /Users/wushaoqiang/Desktop/app源码/游戏/ai_super_app
export PATH="/Users/wushaoqiang/development/flutter/bin:$PATH"
flutter build ios --release --dart-define=API_BASE_URL=http://<Mac局域网IP>:8000
flutter install -d <iPhone设备ID> --release
```

本机已验证的真机运行地址为 `http://192.168.0.11:8000`，设备为 `00008150-001242A402F3401C`。

## 验证命令

```bash
cd /Users/wushaoqiang/Desktop/app源码/游戏/ai_super_app
export PATH="/Users/wushaoqiang/development/flutter/bin:$PATH"
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

批量验证后端模块：

```bash
for module in companion avatar treehole writing office_doc image_fix dressup study knowledge resume career; do
  http_code=$(curl -s -o /tmp/lingxi_${module}.json -w "%{http_code}" -X POST "http://127.0.0.1:8000/api/modules/${module}/run" -H 'Content-Type: application/json' -d '{"text":"测试功能","mode":"check"}')
  bytes=$(wc -c < /tmp/lingxi_${module}.json | tr -d ' ')
  printf "%s %s %s bytes\n" "$module" "$http_code" "$bytes"
done
```

## 当前说明

- 当前版本是可运行 Flutter UI + FastAPI 真实 AI Gateway。
- 11 个模块都有独立页面、输入框、结果区和后端接口。
- 有可用 API Key 时返回真实 AI 结果；模型报错、限流或无 Key 时自动回落到本地兜底结果。
- 前端已拆分为 `models/`、`data/`、`services/`、`screens/`、`widgets/`。
- 后端已拆分为 `ai_gateway.py`、`prompts.py`、`modules.py`、`fallbacks.py`、`main.py`。
