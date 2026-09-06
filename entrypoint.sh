#!/bin/bash
# 
# 1) 创建并显式指定 XDG 运行时目录，给 Fcitx5 搭建好通信总线
mkdir -p /run/user/0
chmod 700 /run/user/0

# 2. 启动虚拟显示器 (:1) 并给它一点初始化时间
Xvfb :1 -screen 0 1280x720x24 &
sleep 2

# . 设置图形环境变量，并在虚拟显示器中拉起 gedit
export DISPLAY=:1

# 3. 【终极闭环核心：在后台拉起系统级 DBus 守护总线】
# 这一步会创建 /var/run/dbus/system_bus_socket，彻底让 fcitx5、chromium 和系统剪贴板相互打通！
mkdir -p /var/run/dbus
dbus-uuidgen --ensure
dbus-daemon --system --fork


# 4. 【核心新增：修改桌面的 Firefox 快捷方式，强制注入免沙箱启动参数】
# 用 sed 把 Exec=firefox 改为 Exec=firefox --no-sandbox，保证双击桌面图标时 100% 成功弹窗
if [ -f /root/Desktop/firefox.desktop ]; then
    sed -i 's/Exec=firefox/Exec=firefox --no-sandbox/g' /root/Desktop/firefox.desktop
fi
# 5. 修改桌面的 Chromium 快捷参数绕过容器内核沙箱限制
# 用 sed 强制让桌面的双击图标带上 --no-sandbox、--disable-gpu 参数启动，确保 100% 成功秒开窗
# --single-process --disable-software-rasterizer 先不加
if [ -f /root/Desktop/chromium.desktop ]; then
    sed -i 's%Exec=/usr/bin/chromium-browser%Exec=/usr/bin/chromium-browser  --no-sandbox --disable-gpu --disable-dev-shm-usage%g' /root/Desktop/chromium.desktop
fi

# 6. 【终极闭环核心：将所有图形和输入法组件整体塞入同一个 dbus 隔离圈】
# 这会强制让 fcitx5、pcmanfm（负责双击图标）、mousepad 和 Openbox 在启动的第一秒完全共享同一个由 UNIX 套接字生成的、合规的 DBus 会话环境！
dbus-run-session -- bash -c '
    export XDG_CONFIG_HOME="/usr/share"
    export XMODIFIERS="@im=fcitx"
    export GTK_IM_MODULE="fcitx"
    export QT_IM_MODULE="fcitx"
    export LANG="zh_CN.UTF-8"
    openbox-session & 
    sleep 1
    pcmanfm --desktop & 
    sleep 1
    fcitx5 -d --replace & 
    sleep 1
    xfce4-panel &
    sleep 1
    export GLYCIN_DISABLE_SANDBOX=1 
    mousepad &
    sleep 1
    terminator &
    sleep 1
    # 保持会话不退出
    wait
' & \
sleep 2


# 7. 启动需密的 VNC 桌面服务端
export GLYCIN_DISABLE_SANDBOX=1 
x11vnc -forever -shared -display :1 -rfbauth /root/.vnc/passwd -bg -ncache 10 && \
sleep 1

# AUTO_ACCESS=true PORT=3000 python3 app.py
# 8. 【最核心的保活】用 exec 让 websockify 成为容器的 1 号主进程 (PID 1)
# 这样它就会死死钉在前台，绝对不会退出，Railway 的健康检查就能 100% 通过
exec /usr/sbin/sshd && python3 -m websockify --web /opt/novnc  0.0.0.0:${PORT:-8080} 127.0.0.1:5900
