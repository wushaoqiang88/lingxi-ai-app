#!/bin/bash
# 灵犀 AI 后端 - 一键部署/更新脚本
# 用法: ./deploy.sh
# 
# 功能：将本地后端代码同步到云服务器，重建 Docker 镜像并重启容器

set -e

SERVER="root@1.15.150.7"
REMOTE_DIR="/opt/lingxi-backend"
LOCAL_BACKEND="$(dirname "$0")/backend"

echo "🚀 灵犀 AI 后端部署脚本"
echo "========================"

# 1. 上传后端代码（排除 __pycache__ 和 .pyc）
echo "📦 上传后端代码到服务器..."
scp -r "$LOCAL_BACKEND/app" "$LOCAL_BACKEND/requirements.txt" "$LOCAL_BACKEND/Dockerfile" "$LOCAL_BACKEND/.dockerignore" "$SERVER:$REMOTE_DIR/"
echo "✅ 代码上传完成"

# 2. 在服务器上重建镜像并重启容器
echo "🔨 重建 Docker 镜像并重启容器..."
ssh "$SERVER" bash -s << 'REMOTE_SCRIPT'
set -e
cd /opt/lingxi-backend

# 重建镜像
echo "Building Docker image..."
docker build --no-cache -t lingxi-backend:latest . 2>&1 | tail -5

# 停止并删除旧容器
echo "Restarting container..."
docker stop lingxi_backend 2>/dev/null || true
docker rm lingxi_backend 2>/dev/null || true

# 启动新容器
docker run -d --name lingxi_backend --restart unless-stopped \
  --network idphoto_deploy_default \
  --env-file /opt/lingxi-backend/.env \
  -v /opt/lingxi-backend/generated_docs:/app/generated_docs \
  -v /opt/lingxi-backend/logs:/app/logs \
  lingxi-backend:latest

# 等待启动
sleep 3

# 健康检查
HEALTH=$(docker exec lingxi_backend python3 -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8000/health').read().decode())" 2>&1)
echo "Health check: $HEALTH"

# 清理旧镜像
docker image prune -f 2>/dev/null || true
echo "✅ 部署完成"
REMOTE_SCRIPT

echo ""
echo "🎉 部署成功！"
echo "   Health: https://api.kktu.top/health"
echo "   Modules: https://api.kktu.top/api/modules"
