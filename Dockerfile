FROM ubuntu:26.04

# 1. Interaktive Prompts verhindern und System-Pip erlauben
ARG DEBIAN_FRONTEND=noninteractive

# 2. KDE Plasma, GStreamer, Sound, Supervisor & Grafiktreiber installieren
# Aktualisierte und bereinigte Paketliste für Ubuntu 26.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    kde-plasma-desktop \
    plasma-desktop \
    python3-pip \
    python3-dev \
    python3-gi \
    libgirepository1.0-dev \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-gl \
    libgstrtspserver-1.0-dev \
    libges-1.0-dev \
    xvfb \
    xserver-xorg-video-dummy \
    xdotool \
    wmctrl \
    x11-utils \
    x11-xserver-utils \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libegl1 \
    libegl-mesa0 \
    mesa-utils \
    mesa-va-drivers \
    pulseaudio \
    pulseaudio-utils \
    alsa-utils \
    nginx \
    curl \
    ca-certificates \
    jq \
    dbus-x11 \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Selkies Python WebRTC Komponenten installieren
RUN pip3 install --break-system-packages --no-cache-dir build tomli meson ninja && \
    pip3 install --break-system-packages --no-cache-dir selkies

# 4. Verzeichnisse vorbereiten und DBus-ID generieren
RUN mkdir -p /var/log/supervisor /var/run/dbus && dbus-uuidgen --ensure

# 5. Konfigurationen kopieren (Nutzt die supervisord.conf aus der vorherigen Nachricht)
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 6. Umgebungsvariablen setzen
ENV DISPLAY=:1
ENV LIBGL_ALWAYS_SOFTWARE=0

EXPOSE 3000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
