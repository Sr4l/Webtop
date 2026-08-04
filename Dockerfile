# syntax=docker/dockerfile:1
#
# Ubuntu 26.04 + KDE Plasma webtop streamed by Selkies (new pixelflux/pcmflux
# architecture, no GStreamer). The selkies wheel is not published to PyPI in
# its new form, so it is built from source here exactly like upstream's own
# Dockerfile does: stage 1 builds the HTML5 web client, stage 2 bundles it
# into the Python wheel, stage 3 is the runtime.

# 1) Build the web client (core + dashboard + keyboard-layout DB + touch gamepad)
FROM docker.io/library/node:22-alpine AS web-build

ARG SELKIES_REF=main
ARG SELKIES_MODE=webrtc
ARG SELKIES_UPLOAD_DIR=/home/ubuntu/Desktop

RUN apk add --no-cache git \
    && git clone https://github.com/selkies-project/selkies.git /src \
    && cd /src && git checkout "${SELKIES_REF}"

WORKDIR /build

RUN set -eux; \
    cp -r /src/addons/selkies-web-core ./selkies-web-core; \
    cp -r /src/addons/selkies-dashboard ./selkies-dashboard; \
    cp -r /src/addons/universal-touch-gamepad ./universal-touch-gamepad; \
    cd selkies-web-core; \
    npm install --no-audit --no-fund; \
    npm run build; \
    cd ../selkies-dashboard; \
    cp ../selkies-web-core/dist/selkies-core.js src/; \
    npm install --no-audit --no-fund; \
    SELKIES_INJECT=1 SELKIES_MODE="${SELKIES_MODE}" SELKIES_UPLOAD_DIR="${SELKIES_UPLOAD_DIR}" npm run build; \
    mkdir -p dist/src; \
    cp ../selkies-web-core/dist/selkies-core.js dist/src/; \
    cp ../universal-touch-gamepad/universalTouchGamepad.js dist/src/; \
    cp -r ../selkies-web-core/dist/jsdb dist/; \
    mkdir -p /webout; \
    cp -ar dist/. /webout/; \
    printf '%s' '{"name":"Selkies","short_name":"Selkies","manifest_version":2,"version":"1.0.0","display":"fullscreen","background_color":"#000000","theme_color":"#000000","icons":[{"src":"icon.png","type":"image/png","sizes":"512x512"}],"start_url":"/"}' > /webout/manifest.json; \
    cp /src/docs/assets/logo/icon-512x512.png /webout/icon.png; \
    cp /src/docs/assets/logo/favicon.ico /webout/favicon.ico

# 2) Build the Python wheel with the web client bundled
FROM docker.io/library/python:3-slim AS py-build

RUN python3 -m pip install --no-cache-dir --upgrade build

WORKDIR /opt/pypi

COPY --from=web-build /src/src ./src
COPY --from=web-build /src/README.md /src/pyproject.toml ./
# Include the production built web files in the wheel package
COPY --from=web-build /webout ./src/selkies/selkies_web

# Build the wheel directly from the source tree (no sdist round-trip) so the
# bundled web client in src/selkies/selkies_web reliably ends up in the wheel
RUN python3 -m build --wheel

# 3) Runtime: Ubuntu 24.04 + KDE Plasma (X11 on Xvfb) + PulseAudio + Selkies
FROM docker.io/library/ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

# Use German mirror servers for faster downloads
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://de.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources

# Desktop/runtime dependencies (per official docs + upstream example container)
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Base utilities
    ca-certificates \
    curl \
    jq \
    sudo \
    supervisor \
    dbus \
    dbus-x11 \
    tzdata \
    # Python runtime
    python3 \
    python3-pip \
    # X11 display server and utilities
    xserver-xorg-core \
    xvfb \
    wmctrl \
    x11-utils \
    x11-xkb-utils \
    x11-xserver-utils \
    xauth \
    # X11 client libraries required by pixelflux (XShm capture) and input injection
    libx11-xcb1 \
    libxcb1 \
    libxcb-shm0 \
    libxcb-xfixes0 \
    libxcb-randr0 \
    libxcb-dri3-0 \
    libxkbcommon0 \
    libxdamage1 \
    libxfixes3 \
    libxtst6 \
    libxext6 \
    # Audio (PulseAudio server used by pcmflux through libpulse)
    libpulse0 \
    libopus0 \
    pulseaudio \
    # Software OpenGL for KDE on Xvfb (llvmpipe)
    libgl1 \
    libgl1-mesa-dri \
    libegl1 \
    mesa-utils \
    # KDE Plasma desktop (X11 session)
    kde-plasma-desktop \
    kwin-x11 \
    # Fonts
    fonts-dejavu-core \
    fonts-liberation \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Selkies wheel (pulls pixelflux/pcmflux and co. from PyPI).
# Build deps for any pip package without a prebuilt wheel are purged afterwards.
COPY --from=py-build /opt/pypi/dist/*.whl /tmp/wheels/
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libxkbcommon-dev \
    pkg-config \
    && PIP_BREAK_SYSTEM_PACKAGES=1 pip3 install --no-cache-dir --ignore-installed cryptography /tmp/wheels/*.whl \
    && apt-get purge -y --autoremove gcc python3-dev libxkbcommon-dev pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/wheels

# The ubuntu:26.04 base already ships an "ubuntu" user (uid 1000); give it
# passwordless sudo and a proper runtime dir (KDE/PulseAudio misbehave as root)
RUN echo "ubuntu ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && mkdir -p /var/log/supervisor /var/run/dbus /tmp/runtime-ubuntu \
    && dbus-uuidgen --ensure \
    && chown ubuntu:ubuntu /tmp/runtime-ubuntu \
    && chmod 700 /tmp/runtime-ubuntu \
    # Disable KWin compositing: Xvfb + llvmpipe has no usable GPU compositing
    && mkdir -p /home/ubuntu/.config \
    && printf '[Compositing]\nEnabled=false\n' > /home/ubuntu/.config/kwinrc \
    && chown -R ubuntu:ubuntu /home/ubuntu/.config

# Supervisord service stack
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV DISPLAY=:1
ENV TZ=UTC+2
ENV LC_ALL=de_DE.UTF-8

EXPOSE 3000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
