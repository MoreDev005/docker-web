FROM --platform=linux/amd64 jrei/systemd-ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Desktop, Tools, & Prasyarat Docker
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm vim net-tools curl wget git tzdata dbus-x11 x11-utils \
    x11-xserver-utils x11-apps software-properties-common xubuntu-icon-theme \
    ca-certificates gnupg lsb-release

# 2. Install Docker Engine (Docker in Docker)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt update -y && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 3. Setup Firefox PPA
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox

# 4. Script Startup (VNC + Cleanup Docker)
RUN printf '#!/bin/bash\n\
rm -rf /tmp/.X*-lock /tmp/.X11-unix\n\
# Pastikan docker socket siap\n\
vncserver -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE\n\
openssl req -new -subj "/C=JP" -x509 -days 365 -nodes -out /self.pem -keyout /self.pem\n\
websockify --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901\n' > /usr/local/bin/vnc-start.sh && \
chmod +x /usr/local/bin/vnc-start.sh

# 5. Service Configuration
RUN printf '[Unit]\nDescription=VNC noVNC Service\nAfter=network.target\n\n[Service]\nExecStart=/usr/local/bin/vnc-start.sh\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/vnc-desktop.service

# Enable Services
RUN systemctl enable vnc-desktop.service && systemctl enable docker

RUN touch /root/.Xauthority
EXPOSE 5901
EXPOSE 6080

# Gunakan instruksi jrei untuk menjalankan systemd
