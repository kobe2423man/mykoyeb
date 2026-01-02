#!/bin/sh

# ==========================================
# 用户配置区 (如果没有设置环境变量，则使用这些默认值)
# ==========================================
# 默认 UUID (如果环境变量没填，会自动生成一个随机的)
UUID=${UUID:-$(uuidgen)}
# WebSocket 路径 (千万别用 /，一定要长一点，复杂一点)
WS_PATH=${WS_PATH:-"vless-chat-secret"}
# 伪装站点的下载地址 (这里用的是一个开源的 3D 元素周期表，看起来很像正经技术展示页)
# 你也可以换成 2048 游戏： https://github.com/gabrielecirulli/2048/archive/refs/heads/master.zip
WEB_URL="https://github.com/mrdoob/three.js/archive/refs/tags/r150.zip"
# 核心程序下载地址 (Xray)
CORE_URL="https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-linux-64.zip"
# 伪装后的进程名 (看起来像 web 服务进程)
BIN_NAME="nginx-worker"

# ==========================================
# 1. 部署伪装站点 (Web Camouflage)
# ==========================================
echo "正在部署伪装站点..."
mkdir -p /app/www
# 这里我们在本地启动一个极简的 Web 服务器，监听 8081 端口
# 当 Xray 发现流量不是代理流量时，会把流量转给这个 8081
# 写入一个简单的 Hello World 或者下载复杂模板
cat <<EOF > /app/www/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to My Service</title>
<style>
    body { font-family: sans-serif; text-align: center; padding-top: 50px; background-color: #f0f0f0; }
    h1 { color: #333; }
    p { color: #666; }
</style>
</head>
<body>
    <h1>Service is Running</h1>
    <p>The backend application is synchronized successfully.</p>
    <p>&copy; 2024 Tech Corp. All rights reserved.</p>
</body>
</html>
EOF

# 在后台启动 Busybox 自带的 httpd 服务器，根目录指向 /app/www，监听 8081
httpd -h /app/www -p 8081
echo "伪装站点已启动 (Port 8081)"

# ==========================================
# 2. 部署核心节点程序
# ==========================================
echo "正在下载节点核心..."
wget -qO core.zip $CORE_URL
unzip -q core.zip
mv xray $BIN_NAME
rm -f core.zip *.dat LICENSE README.md
chmod +x $BIN_NAME

# ==========================================
# 3. 生成抗封锁配置文件 (Anti-Ban Config)
# ==========================================
echo "正在生成高级配置 (UUID: $UUID)..."

cat <<EOF > config.json
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": 8080,
      "listen": "0.0.0.0",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 8081
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/$WS_PATH"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# ==========================================
# 4. 启动服务
# ==========================================
echo "服务启动成功！"
echo "您的节点路径 (Path): /$WS_PATH"
echo "您的 UUID: $UUID"
echo "请在 Koyeb 环境变量中记录这些信息。"

# 启动核心
./$BIN_NAME -c config.json
