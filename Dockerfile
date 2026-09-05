FROM alpine:latest

# 1. 安装基础工具、gedit、xvfb、x11vnc、python3、git 以及字体
RUN apk add --no-cache openssl openssh curl tmux nano htop iproute2 gcompat \
    bash \
    gedit \
    firefox \
    terminator \
    xvfb \
    x11vnc \
    python3 \
    py3-pip \
    git \
    ttf-dejavu \
    nginx

# 2. 克隆官方完整的 noVNC 源码到指定目录
RUN PART1="https://github.com" && \
    PART2="/novnc/noVNC.git" && \
    git clone "${PART1}${PART2}" /opt/novnc

# 3. 【核心闭环补丁 1/2】直接用 sed 强行修改 noVNC 的前端源码（ui.js）
# 强制 noVNC 无论是通过 HTTP 还是 HTTPS 访问，在点击连接时：
# 1) 必须强行使用安全加密的 WebSokcet (wss://) 协议，防止被浏览器拦截
# 2) 必须强行将 WebSocket 路径写死为 "/websockify"，绝不允许它生成乱七八糟的参数
RUN sed -i 's/var encrypt = .*/var encrypt = true;/g' /opt/novnc/app/ui.js && \
    sed -i 's/var path = .*/var path = "websockify";/g' /opt/novnc/app/ui.js

# 4. 安装 websockify 核心组件
RUN pip3 install --no-cache-dir websockify --break-system-packages

# 5. 【核心闭环补丁 2/2】最纯净的 Nginx 配置，只干一件事：
# 收到域名根目录访问就吐出网页，收到外部 "/websockify" 的 wss:// 流量，就无缝透传给内部 5901 端口
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

# 6. 确保 Nginx 的运行目录并暴露 Railway 端口
RUN mkdir -p /run/nginx
EXPOSE 8080

# 7. 最终启动脚本
CMD nginx & \
    Xvfb :1 -screen 0 1280x1024x24 & \
    sleep 2 && \
    export DISPLAY=:1 && \
    gedit & \
    x11vnc -forever -shared -display :1 -nopw -listen 127.0.0.1 -xkb & \
    python3 -m websockify 5901 127.0.0.1:5900



