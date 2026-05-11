#!/bin/zsh
# 灵犀 AI 后端启动脚本 - 由 launchd 调用
# 自动 cd 到 backend 目录并启动 uvicorn

PROJECT_DIR="/Users/wushaoqiang/lingxi-project"
BACKEND_DIR="$PROJECT_DIR/backend"
VENV_PYTHON="$PROJECT_DIR/.venv/bin/python"

cd "$BACKEND_DIR" || exit 1

exec "$VENV_PYTHON" -m uvicorn app.main:app --host 0.0.0.0 --port 8000
