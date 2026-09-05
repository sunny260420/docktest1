#!/bin/bash
# 0. 【核心新增：解决输入法闪退与剪贴板 ?? 乱码】
# 1) 创建并显式指定 XDG 运行时目录，给 Fcitx5 搭建好通信总线
mkdir -p /run/user/0

chmod 700 /run/user/0



# 1. 启动虚拟显示器 (:1) 并给它一点初始化时间
Xvfb :1 -screen 0 1280x720x24 &
sleep 2

# 2. 设置图形环境变量，并在虚拟显示器中拉起 gedit
export DISPLAY=:1
# . 【终极闭环核心：在后台拉起系统级 DBus 守护总线】
# 这一步会创建 /var/run/dbus/system_bus_socket，彻底让 fcitx5、chromium 和系统剪贴板相互打通！
mkdir -p /var/run/dbus
dbus-uuidgen --ensure
dbus-daemon --system --fork
# 【核心修复 2/2：启动 DBus 会话总线】
# 这一步会将 DBUS_SESSION_BUS_ADDRESS 注入环境，打通 fcitx5 与 mousepad 的底层桥梁

eval $(dbus-launch --sh-syntax)

# 3. 【核心闭环：显式注入中文输入法全局环境变量】
# 这四行命令将强制让 mousepad 这样的 GTK 程序在按下快捷键时去调用小企鹅输入法
#export XMODIFIERS="@im=fcitx"
#export GTK_IM_MODULE="fcitx"
#export QT_IM_MODULE="fcitx"
# 4. 【核心新增：修改桌面的 Firefox 快捷方式，强制注入免沙箱启动参数】
# 用 sed 把 Exec=firefox 改为 Exec=firefox --no-sandbox，保证双击桌面图标时 100% 成功弹窗
if [ -f /root/Desktop/firefox.desktop ]; then
    sed -i 's/Exec=firefox/Exec=firefox --no-sandbox/g' /root/Desktop/firefox.desktop
fi
# 5. 修改桌面的 Chromium 快捷参数绕过容器内核沙箱限制
# 用 sed 强制让桌面的双击图标带上 --no-sandbox、--disable-gpu 参数启动，确保 100% 成功秒开窗
# --single-process --disable-software-rasterizer 先不加
if [ -f /root/Desktop/chromium.desktop ]; then
    sed -i 's/Exec=chromium-browser/Exec=chromium-browser --no-sandbox --disable-gpu --disable-dev-shm-usage/g' /root/Desktop/chromium.desktop
fi

# 5. 【核心修复：用 dbus-run-session 包裹拉起窗口管理器 Openbox】
# 这会强制在 Openbox 内部诞生一个完美的、100% 能被解析的 UNIX Domain Socket 的 DBus 总线环境！
dbus-run-session -- openbox-session &
sleep 1
# 5. 【强行拉起桌面图标绘制引擎】
# --desktop 参数会接管壁纸和 root/Desktop 目录下的图标渲染
pcmanfm --desktop & \
sleep 1
# 6. 激活剪贴板桥梁
#autocutsel -s CLIPBOARD -fork &
#autocutsel -s PRIMARY -fork &
# 7. 【核心常驻：在后台默默拉起 fcitx5 输入法进程】
# -d 表示以守护进程常驻后台，确保它比应用先启动

fcitx5 -d & \
sleep 1
terminator &
# 8. 启动默认要弹出的主 GUI 应用（加入关闭 Glycin 沙箱的保底设置）

export GLYCIN_DISABLE_SANDBOX=1
mousepad &
# firefox &

sleep 1

# 9. 启动需密的 VNC 桌面服务端
x11vnc -forever -shared -display :1 -rfbauth /root/.vnc/passwd -bg && \
sleep 1

# 10. 【最核心的保活】用 exec 让 websockify 成为容器的 1 号主进程 (PID 1)
# 这样它就会死死钉在前台，绝对不会退出，Railway 的健康检查就能 100% 通过
exec python3 -m websockify --web /opt/novnc 0.0.0.0:${PORT:-8080} 127.0.0.1:5900
