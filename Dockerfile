FROM alpine:latest

# 1. 安装基础工具、gedit、xvfb、x11vnc、python3、git 以及字体
RUN apk add --no-cache openssl openssh bash gedit mousepad curl tmux nano htop iproute2 gcompat \
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
    py3-xdg \
    bubblewrap \
    font-noto-cjk \
    fcitx5 \
    fcitx5-gtk3 \
    fcitx5-chinese-addons \
    pcmanfm \
    adwaita-icon-theme

# 2. 拼接克隆官方完整的 noVNC 源码到 /opt/novnc
RUN PART1="https://github.com" && \
    PART2="/novnc/noVNC.git" && \
    git clone "${PART1}${PART2}" /opt/novnc

# 3. 安装 websockify
RUN pip3 install --no-cache-dir websockify --break-system-packages

# 4. 复制为默认首页
RUN cp /opt/novnc/vnc.html /opt/novnc/index.html

# 【核心新增：彻底解决 machine-id 报错】
# 创建系统和 dbus 预期的机器特征码路径，并随机写入一个 32 位的 uuid 标识符
RUN mkdir -p /var/lib/dbus /etc && \
    echo $(head -c 32 /dev/urandom | md5sum | cut -d" " -f1) > /var/lib/dbus/machine-id && \
    ln -sf /var/lib/dbus/machine-id /etc/machine-id
#【核心自动化】在系统构建时，把系统自带的应用快捷方式直接复制到桌面上
# Linux 的应用快捷方式默认都在 /usr/share/applications 里，我们提前创建桌面文件夹并拷过去

RUN mkdir -p /root/Desktop && \
    cp /usr/share/applications/org.xfce.mousepad.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/org.gnome.gedit.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/firefox.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/terminator.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/htop.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/xfce4-about.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/fcitx5-configtool.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/org.fcitx.Fcitx5.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/org.fcitx.fcitx5-qt6-gui-wrapper.desktop /root/Desktop/ 2>/dev/null || true

# EXPOSE 8080

# 5. 将启动脚本复制进容器，并赋予绝对的可执行权限
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 6. 容器启动时直接调用该脚本
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
