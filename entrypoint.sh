#!/bin/bash

# 1) XDG runtime directory
mkdir -p /run/user/0
chmod 700 /run/user/0

# 2) Start TigerVNC's X server directly.
#    Xvnc replaces BOTH Xvfb + x11vnc.
mkdir -p /root/.vnc

Xvnc :1 \
    -geometry 1280x720 \
    -depth 24 \
    -rfbauth /root/.vnc/passwd \
    -localhost no &

sleep 2

# 3) Graphical environment
export DISPLAY=:1

# 4) DBus
mkdir -p /var/run/dbus
dbus-uuidgen --ensure
dbus-daemon --system --fork

# 5) Firefox desktop shortcut
if [ -f /root/Desktop/firefox.desktop ]; then
    sed -i 's/Exec=firefox/Exec=firefox --no-sandbox/g' \
        /root/Desktop/firefox.desktop
fi

# 6) Chromium desktop shortcut
if [ -f /root/Desktop/chromium.desktop ]; then
    sed -i 's%Exec=/usr/bin/chromium-browser%Exec=/usr/bin/chromium-browser --no-sandbox --disable-gpu --disable-dev-shm-usage --no-first-run%g' \
        /root/Desktop/chromium.desktop
fi

# 7) Desktop session
dbus-run-session -- bash -c '
    openbox-session &
    sleep 1

    pcmanfm --desktop &
    sleep 1

    fcitx5 -d &
    sleep 1

    terminator &
    sleep 1

    export GLYCIN_DISABLE_SANDBOX=1
    mousepad &

    wait
' &

sleep 2

# 8) noVNC
# Xvnc itself listens on TCP 5901 for display :1.
exec python3 -m websockify \
    --web /opt/novnc \
    0.0.0.0:${PORT:-8080} \
    127.0.0.1:5901
