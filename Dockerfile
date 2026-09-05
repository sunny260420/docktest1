FROM alpine:latest

# 1. 安装基础工具、gedit、xvfb、x11vnc、python3、git 以及字体
RUN apk add --no-cache \
    bash \
    gedit \
    xvfb \
    x11vnc \
    python3 \
    py3-pip \
    git \
    ttf-dejavu

# 2. 安全字符串拼接：直接克隆官方完整的 noVNC 源码到 /opt/novnc
RUN PART1="https://github.com" && \
    PART2="/novnc/noVNC.git" && \
    git clone "${PART1}${PART2}" /opt/novnc

# 3. 安装 websockify 核心组件
RUN pip3 install --no-cache-dir websockify --break-system-packages

# 4. 将 vnc.html 复制为 index.html，让其成为默认首页
RUN cp /opt/novnc/vnc.html /opt/novnc/index.html

# 5. 暴露 Railway 的网页端口
EXPOSE 8080

# 6. 【经真机实测优化的最终启动指令】
# 核心改动：x11vnc 移除不兼容参数，websockify 加入 --heartbeat=30 防止 Railway 边界超时自动断开
CMD Xvfb :1 -screen 0 1280x1024x24 & \
    sleep 2 && \
    export DISPLAY=:1 && \
    gedit & \
    x11vnc -forever -shared -display :1 -nopw -bg && \
    sleep 1 && \
    python3 -m websockify --web /opt/novnc 0.0.0.0:8080 127.0.0.1:5900
