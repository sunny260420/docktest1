FROM alpine:latest

# 1. 安装基础工具、gedit、xvfb、x11vnc、python3、git 以及字体
RUN apk add --no-cache openssl openssh bash gedit curl tmux nano htop iproute2 gcompat \
    terminator \
    firefox \
    xvfb \
    x11vnc \
    python3 \
    py3-pip \
    git \
    ttf-dejavu \
    autocutsel \
    openbox \
    py3-xdg

# 2. 拼接克隆官方完整的 noVNC 源码到 /opt/novnc
RUN PART1="https://github.com" && \
    PART2="/novnc/noVNC.git" && \
    git clone "${PART1}${PART2}" /opt/novnc

# 3. 安装 websockify
RUN pip3 install --no-cache-dir websockify --break-system-packages

# 4. 复制为默认首页
RUN cp /opt/novnc/vnc.html /opt/novnc/index.html

# 5. 将启动脚本复制进容器，并赋予绝对的可执行权限
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 6. 容器启动时直接调用该脚本
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
