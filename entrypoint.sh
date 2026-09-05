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
openbox-session &
sleep 1

# 激活剪贴板桥梁
autocutsel -s CLIPBOARD -fork && \
autocutsel -s PRIMARY -fork && \
# 5. 【核心常驻：在后台默默拉起 fcitx5 输入法进程】
# -d 表示以守护进程常驻后台，确保它比应用先启动
export GLYCIN_DISABLE_SANDBOX=1
fcitx5 -d &
terminator &
sleep 1

# 3. 启动免密的 VNC 桌面服务端
x11vnc -forever -shared -display :1 -nopw -bg && \
sleep 1

# 4. 【最核心的保活】用 exec 让 websockify 成为容器的 1 号主进程 (PID 1)
# 这样它就会死死钉在前台，绝对不会退出，Railway 的健康检查就能 100% 通过
exec python3 -m websockify --web /opt/novnc --auth-plugin=ServerTokenApi --auth-source="vnc:demo2026" 0.0.0.0:${PORT:-8080} 127.0.0.1:5900
