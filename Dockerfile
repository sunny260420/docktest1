FROM python:3.13-alpine

# 1. 安装基础工具、mousepad、xvfb、x11vnc、python3、git 以及字体
RUN apk add --no-cache openssl openssh bash mousepad curl tmux nano htop btop iproute2 gcompat \
    terminator \
    firefox \
    chromium \
    xterm \
    xvfb \
    x11vnc \
    python3 \
    py3-pip \
    git \
    ttf-dejavu \
    xfce4-panel \
    openbox \
    py3-xdg \
    bubblewrap \
    font-noto-cjk \
    font-wqy-zenhei \
    fcitx5 \
    fcitx5-gtk3 \
    fcitx5-configtool \
    fcitx5-chinese-addons \
    fcitx5-table-extra \
    fcitx5-table-other \
    pcmanfm \
    adwaita-icon-theme \
    musl-locales \
    dbus \
    gnu-libiconv \
    btop \
    bottom \
    xfce4-terminal

# 2. 【核心修复 1/2】用最高级别的系统 ENV 锁死全通用 UTF-8 环境与输入法路径
# 这样能从容器诞生的第一秒，强制内核采用 C.UTF-8 编解码，彻底杜绝剪贴板降级变成 ??
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    XDG_RUNTIME_DIR=/run/user/0 \
    XMODIFIERS=@im=fcitx5 \
    GTK_IM_MODULE=fcitx5 \
    QT_IM_MODULE=fcitx5

# 3. 拼接克隆官方完整的 noVNC 源码到 /opt/novnc
RUN PART1="https://github.com" && \
    PART2="/novnc/noVNC.git" && \
    git clone "${PART1}${PART2}" /opt/novnc

# 4. 安装 websockify
RUN pip3 install --no-cache-dir websockify --break-system-packages


# 5. 复制为默认首页
RUN cp /opt/novnc/vnc.html /opt/novnc/index.html

# 6. 【核心新增：彻底解决 machine-id 报错】
# 创建系统和 dbus 预期的机器特征码路径，并随机写入一个 32 位的 uuid 标识符
RUN mkdir -p /var/lib/dbus /etc && \
    echo $(head -c 32 /dev/urandom | md5sum | cut -d" " -f1) > /var/lib/dbus/machine-id && \
    ln -sf /var/lib/dbus/machine-id /etc/machine-id


# 7. # 5. 在容器底层预设好 Fcitx5 智能拼音和热键配置 (解决输入法无法切出问题)
RUN mkdir -p /root/.config/fcitx5 && \ 
    echo -e "[Groups/0]\nName=Default\nDefault Layout=us\n[Groups/0/Items/0]\nName=keyboard-us\nLayout=\n[Groups/0/Items/1]\nName=wubi86\nLayout=\n[Groups/0/Items/2]\nName=pinyin\nLayout=" > /root/.config/fcitx5/profile && \
    echo -e "[Hotkey]\nTriggerKeys=\n[Hotkey/TriggerKeys]\n0=Control+space\n1=Control+Shift+space\n[Hotkey/EnumerateKeys]\n0=Control+Shift_L" > /root/.config/fcitx5/config

# 8. 【vnc加密】
# 
RUN mkdir -p /root/.vnc && \
    x11vnc -storepasswd "Demo2026" /root/.vnc/passwd
    
# 9.【核心自动化】在系统构建时，把系统自带的应用快捷方式直接复制到桌面上
# Linux 的应用快捷方式默认都在 /usr/share/applications 里，我们提前创建桌面文件夹并拷过去  

RUN mkdir -p /root/Desktop && \
    cp /usr/share/applications/org.xfce.mousepad.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/org.gnome.gedit.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/firefox.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/terminator.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/htop.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/xfce4-about.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/chromium.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/btop.desktop /root/Desktop/ 2>/dev/null || true && \
    cp /usr/share/applications/xfce4-terminal.desktop /root/Desktop/ 2>/dev/null || true

EXPOSE 8080 3000 22
COPY app.py /root/app.py
COPY requirements.txt /root/requirements.txt
RUN ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "root:passw0rd" | chpasswd && \ 
    chmod +x /root/app.py
#    pip install -r /root/requirements.txt
# RUN pip3 install --no-cache-dir  install -r /root/requirements.txt  --break-system-packages
# 10. 将启动脚本复制进容器，并赋予绝对的可执行权限
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 11. 容器启动时直接调用该脚本
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
