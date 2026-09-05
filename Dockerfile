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

# 2. 拼接克隆官方完整的 noVNC 源码
RUN PART1="https://github.com" && \
    PART2="/novnc/noVNC.git" && \
    git clone "${PART1}${PART2}" /opt/novnc

# 3. 安装 websockify
RUN pip3 install --no-cache-dir websockify --break-system-packages

# 4. 复制为默认首页
RUN cp /opt/novnc/vnc.html /opt/novnc/index.html

# 5. 【彻底遵从官方】不再写死 EXPOSE 8080，直接交给 Railway 控制台动态绑定

# 6. 【唯一正确的启动指令】
# 核心修正：使用 "$PORT" 替换所有硬编码的 8080 端口。
# 这样无论 Railway 随机分配什么端口，websockify 都能完美挂载并对公网吐出静态网页与长连接。
CMD Xvfb :1 -screen 0 1280x1024x24 & \
    sleep 2 && \
    export DISPLAY=:1 && \
    gedit & \
    x11vnc -forever -shared -display :1 -nopw -bg && \
    sleep 1 && \
    python3 -m websockify --web /opt/novnc 0.0.0.0:$PORT 127.0.0.1:5900
