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
    ttf-dejavu &&\
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "root:passw0rd" | chpasswd && \
    pip install -r requirements.txt

# 2. 安全字符串拼接：直接拼出完整的官方库地址，100% 避免被截断
RUN PART1="https://github.com" && \
    PART2="/novnc/noVNC.git" && \
    git clone "${PART1}${PART2}" /opt/novnc

# 3. 安装 websockify
RUN pip3 install --no-cache-dir websockify --break-system-packages

# 4. 暴露 Railway 的网页端口
EXPOSE 8080 3000 22

# 5. 启动脚本
# 仅修改最后这一个 CMD 指令
CMD Xvfb :1 -screen 0 1280x1024x24 & \
    sleep 2 && \
    /usr/sbin/sshd && \
    export DISPLAY=:1 && \
    gedit & \
    x11vnc -forever -shared -display :1 -nopw -listen 127.0.0.1 -xkb & \
    python3 -m websockify --web /opt/novnc 8080 127.0.0.1:5900 & 
#    AUTO_ACCESS=true PORT=3000 python3 app.py 

