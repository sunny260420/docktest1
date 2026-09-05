#!/bin/bash

# 1. 启动虚拟显示器 (:1) 并给它一点初始化时间
Xvfb :1 -screen 0 1280x1024x24 &
sleep 2

# 2. 设置图形环境变量，并在虚拟显示器中拉起 gedit
export DISPLAY=:1
openbox-session &
sleep 1

# 激活剪贴板桥梁
autocutsel -s CLIPBOARD -fork
autocutsel -s PRIMARY -fork
terminator &
sleep 1

# 3. 启动免密的 VNC 桌面服务端
x11vnc -forever -shared -display :1 -nopw -bg
sleep 1

# 4. 【最核心的保活】用 exec 让 websockify 成为容器的 1 号主进程 (PID 1)
# 这样它就会死死钉在前台，绝对不会退出，Railway 的健康检查就能 100% 通过
exec python3 -m websockify --web /opt/novnc 0.0.0.0::$PORT 127.0.0.1:5900
