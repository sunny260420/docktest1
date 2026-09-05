FROM python:3.13-alpine

ENV PORT=3000
ENV AUTO_ACCESS=true
WORKDIR /app

COPY . .

EXPOSE 8080 3000 22

RUN apk update && apk --no-cache add openssl openssh bash gedit curl tmux nano htop iproute2 gcompat xvfb x11vnc &&\
    apk add --no-cache --repository=http://alpinelinux.org novnc && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "root:passw0rd" | chpasswd && \
    chmod +x app.py &&\
    pip install -r requirements.txt
    
#CMD ["/bin/sh", "-c", "/usr/sbin/sshd && echo 'Starting...' && AUTO_ACCESS=true PORT=3000 python3 app.py "]

CMD Xvfb :1 -screen 0 1280x1024x24 & \
    export DISPLAY=:1 && \
    gedit & \
    x11vnc -forever -shared -display :1 -nopw -listen localhost -xkb & \
    novnc_proxy --listen 0.0.0.0:8080 --vnc localhost:5900
