FROM alpine:latest

# 安装基础工具
# uuidgen 用于随机生成 UUID，nginx/httpd 需要的基础库
RUN apk add --no-cache ca-certificates curl wget tar unzip util-linux

WORKDIR /app

# 复制启动脚本
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# 启动
CMD ["/app/entrypoint.sh"]
