FROM jrei/systemd-ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
  xfce4 xfce4-goodies \
  tigervnc-standalone-server \
  novnc websockify \
  dbus-x11 xterm \
  firefox xubuntu-icon-theme \
  sudo curl wget git vim net-tools \
  tzdata && \
  apt clean && rm -rf /var/lib/apt/lists/*

# Xauthority
RUN touch /root/.Xauthority

# xstartup XFCE
RUN mkdir -p /root/.vnc && \
    printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4 &\n' \
    > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# systemd service VNC
RUN printf '[Unit]\nDescription=TigerVNC Server\nAfter=network.target\n\n[Service]\nType=forking\nUser=root\nPAMName=login\nPIDFile=/root/.vnc/%%H:1.pid\nExecStart=/usr/bin/vncserver :1 -localhost no -SecurityTypes None -geometry 1024x768\nExecStop=/usr/bin/vncserver -kill :1\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target\n' \
    > /etc/systemd/system/vncserver.service

# systemd service noVNC
RUN printf '[Unit]\nDescription=noVNC Web Client\nAfter=network.target vncserver.service\nRequires=vncserver.service\n\n[Service]\nExecStart=/usr/bin/websockify --web=/usr/share/novnc/ 6080 localhost:5901\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n' \
    > /etc/systemd/system/novnc.service

# enable service
RUN systemctl daemon-reexec && \
    systemctl daemon-reload && \
    systemctl enable vncserver.service && \
    systemctl enable novnc.service

EXPOSE 5901 6080

CMD ["/sbin/init"]
