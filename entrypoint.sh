#!/bin/sh

# ==========================================
# 变量配置区
# ==========================================
UUID=${UUID:-$(uuidgen)}
# 这是一个更具迷惑性的路径，看起来像 API 接口
WS_PATH=${WS_PATH:-"api/v3/sync-data"} 

# [核心升级] 伪装网站地址
# 这里选用 StartBootstrap 的 Resume 模板，看起来非常像一个正经开发者的主页
# 如果你想换别的，只需替换这个 ZIP 连接（必须是静态 HTML 网站）
WEB_URL="https://github.com/StartBootstrap/startbootstrap-resume/archive/gh-pages.zip"

# 核心程序 (Xray)
CORE_URL="https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-linux-64.zip"
BIN_NAME="mysql-worker" # 伪装成数据库进程

# ==========================================
# 1. 部署 "高逼真" 伪装站点
# ==========================================
echo "正在构建伪装环境..."
mkdir -p /app/www

# 下载网页模板
echo "正在下载网页模板: $WEB_URL"
wget -qO website.zip $WEB_URL

# 解压并处理目录结构
unzip -q website.zip
# 不同的 zip 包解压出来的文件夹名字不一样，这里用通配符自动识别并移动文件
# 通常解压后会有一个 startbootstrap-resume-gh-pages 文件夹
mv *-gh-pages/* /app/www/ 2>/dev/null || mv */* /app/www/ 2>/dev/null

# 清理垃圾
rm -rf website.zip
rm -rf *-gh-pages

# 简单的修正：防止某些模板引用不到 CSS (可选)
# 确保 index.html 存在，如果不存在，创建一个兜底的
if [ ! -f /app/www/index.html ]; then
    echo "模板下载异常，生成备用页面..."
    echo "<html><body><h1>System Maintenance</h1></body></html>" > /app/www/index.html
fi

# 启动静态 Web 服务器 (Busybox httpd)
# -h 指定根目录, -p 指定监听端口 8081 (内部端口，不公开)
httpd -h /app/www -p 8081
echo "伪装站点已启动 (Port 8081)"

# ==========================================
# 2. 部署核心节点 (同前)
# ==========================================
echo "正在初始化网络核心..."
wget -qO core.zip $CORE_URL
unzip -q core.zip
mv xray $BIN_NAME
chmod +x $BIN_NAME
rm -f core.zip *.dat LICENSE README.md

# ==========================================
# 3. 生成 智能回落 (Fallback) 配置
# ==========================================
echo "生成安全配置 (UUID: $UUID)..."

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
            "dest": 8081,
            "xver": 1
          },
          {
            "path": "/",
            "dest": 8081,
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
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
# 4. 启动
# ==========================================
echo "===================================================="
echo "部署完成！"
echo "伪装页面: Bootstrap Resume Profile"
echo "节点 UUID: $UUID"
echo "节点 Path: /$WS_PATH"
echo "===================================================="

./$BIN_NAME -c config.json
