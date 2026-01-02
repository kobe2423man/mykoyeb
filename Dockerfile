# 1. 选择一个纯净、无害的基础镜像（Alpine 非常小，且绝对安全）
FROM alpine:latest

# 2. 安装必要的基础工具
# ca-certificates 用于处理 HTTPS 证书，curl/wget 用于下载，tar/unzip 用于解压
RUN apk add --no-cache ca-certificates curl wget tar unzip

# 3. 设置工作目录
WORKDIR /app

# 4. 把启动脚本复制进去
COPY entrypoint.sh /app/entrypoint.sh

# 5. 赋予脚本执行权限
RUN chmod +x /app/entrypoint.sh

# 6. 设置容器启动时执行的命令
# 注意：我们不在构建阶段下载核心程序，而是在启动阶段（entrypoint）下载
# 这样镜像本身就是干净的，没有任何敏感文件
CMD ["/app/entrypoint.sh"]
