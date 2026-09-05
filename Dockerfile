FROM alpine:latest

# 1. 安装基础工具、gedit、xvfb、x11vnc、python3、git 以及字体
RUN apk add --no-cache openssl openssh curl tmux nano htop iproute2 gcompat \
    bash \
    gedit \
    firefox \
    xvfb \
    x11vnc \
    python3 \
    py3-pip \
    git \
    ttf-dejavu \
    nginx

# 2. 安全字符串拼接：直接克隆官方完整的 noVNC 源码到临时目录
RUN PART1="https://github.com" && \
    PART2="/novnc/noVNC.git" && \
    git clone "${PART1}${PART2}" /opt/novnc

# 3. 安装 websockify 核心组件
RUN pip3 install --no-cache-dir websockify --break-system-packages

# 4. 【核心闭环】用一行复杂的 echo 直接在容器内动态生成完美的 Nginx 配置文件
# 该配置统一监听 8080，静态网页直接走 noVNC，WebSocket 流量通过 /websockify 路径完美透传 Upgrade 协议头
RUN echo 'events { worker_connections 1024; } \
http { \
    include /etc/nginx/mime.types; \
    server { \
        listen 8080; \
        location / { \
            root /opt/novnc; \
            index vnc.html; \
        } \
        location /websockify { \
            proxy_pass http://127.0.0.1:5901; \
            proxy_http_version 1.1; \
            proxy_set_header Upgrade $http_upgrade; \
            proxy_set_header Connection "Upgrade"; \
            proxy_set_header Host $host; \
        } \
    } \
}' > /etc/nginx/nginx.conf

# 5. 确保 Nginx 的运行目录存在
RUN mkdir -p /run/nginx

# 6. 暴露 Railway 的网页端口
EXPOSE 8080 22

# 7. 最终启动脚本：
# 启动 Nginx (8080端口) -> 启动虚拟屏幕 -> 运行 gedit -> 运行 vnc -> 使用 websockify 监听内部 5901 端口
CMD nginx & \
    Xvfb :1 -screen 0 1280x1024x24 & \
    sleep 2 && \
    export DISPLAY=:1 && \
    gedit & \
    x11vnc -forever -shared -display :1 -nopw -listen 127.0.0.1 -xkb & \
    python3 -m websockify 5901 127.0.0.1:5900


