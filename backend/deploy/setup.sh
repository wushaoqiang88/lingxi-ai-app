#!/bin/bash
# 灵犀后端一键部署脚本 — 在云服务器上执行
set -e

echo "=== 灵犀 AI 后端部署 ==="

# 1. 安装依赖
echo ">>> 安装系统依赖..."
dnf install -y python3.12 python3.12-pip nginx ffmpeg 2>/dev/null || \
dnf install -y python3 python3-pip nginx 2>/dev/null || true

# 2. 创建项目目录
PROJECT_DIR=/opt/lingxi-backend
mkdir -p $PROJECT_DIR/logs $PROJECT_DIR/generated_docs

# 3. 复制代码（假设已上传到 /tmp/backend/）
if [ -d /tmp/backend/app ]; then
    cp -r /tmp/backend/app $PROJECT_DIR/
    cp /tmp/backend/requirements.txt $PROJECT_DIR/
    cp /tmp/backend/.env $PROJECT_DIR/ 2>/dev/null || true
fi

# 4. 创建虚拟环境并安装依赖
cd $PROJECT_DIR
python3 -m venv venv 2>/dev/null || python3.12 -m venv venv
source venv/bin/activate
pip install -i https://mirrors.aliyun.com/pypi/simple/ -r requirements.txt

# 5. 创建 systemd 服务
cat > /etc/systemd/system/lingxi-backend.service << 'EOF'
[Unit]
Description=Lingxi AI Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lingxi-backend
EnvironmentFile=/opt/lingxi-backend/.env
ExecStart=/opt/lingxi-backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 6. 配置 Nginx
if [ -f /tmp/backend/deploy/nginx-api.conf ]; then
    cp /tmp/backend/deploy/nginx-api.conf /etc/nginx/conf.d/api-kktu-top.conf
fi

# 7. 启动服务
systemctl daemon-reload
systemctl enable lingxi-backend
systemctl restart lingxi-backend
systemctl enable nginx
systemctl restart nginx

echo "=== 部署完成 ==="
echo "后端: http://127.0.0.1:8000"
echo "域名: https://api.kktu.top"
systemctl status lingxi-backend --no-pager
