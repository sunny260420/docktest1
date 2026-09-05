#!/bin/bash

# 1. 启动虚拟显示器 (:1) 并给它一点初始化时间
Xvfb :1 -screen 0 1280x720x24 &
sleep 2

# 2. 设置图形环境变量，并在虚拟显示器中拉起 gedit
export DISPLAY=:1
# 3. 【核心闭环：显式注入中文输入法全局环境变量】
# 这四行命令将强制让 mousepad 这样的 GTK 程序在按下快捷键时去调用小企鹅输入法
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
# 4. 【核心新增：修改桌面的 Firefox 快捷方式，强制注入免沙箱启动参数】
# 用 sed 把 Exec=firefox 改为 Exec=firefox --no-sandbox，保证双击桌面图标时 100% 成功弹窗
if [ -f /root/Desktop/firefox.desktop ]; then
    sed -i 's/Exec=firefox/Exec=firefox --no-sandbox/g' /root/Desktop/firefox.desktop
fi
openbox-session &
sleep 1
# 5. 【强行拉起桌面图标绘制引擎】
# --desktop 参数会接管壁纸和 root/Desktop 目录下的图标渲染
pcmanfm --desktop & \
# 6. 激活剪贴板桥梁
autocutsel -s CLIPBOARD -fork && \
autocutsel -s PRIMARY -fork && \
# 7. 【核心常驻：在后台默默拉起 fcitx5 输入法进程】
# -d 表示以守护进程常驻后台，确保它比应用先启动
fcitx5 -d &
# 8. 启动默认要弹出的主 GUI 应用（加入关闭 Glycin 沙箱的保底设置）
export GLYCIN_DISABLE_SANDBOX=1
terminator &
sleep 1

# 9. 启动免密的 VNC 桌面服务端
x11vnc -forever -shared -display :1 -nopw -bg && \
sleep 1

# 10. 【最核心的保活】用 exec 让 websockify 成为容器的 1 号主进程 (PID 1)
# 这样它就会死死钉在前台，绝对不会退出，Railway 的健康检查就能 100% 通过
exec python3 -m websockify --web /opt/novnc --auth-plugin=ServerTokenApi --auth-source="vnc:demo2026" 0.0.0.0:${PORT:-8080} 127.0.0.1:5900
