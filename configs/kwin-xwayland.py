#!/usr/bin/env python3
"""Start nested KWin on top of the pixelflux headless compositor.

pixelflux (started by selkies) owns the capture compositor on wayland-1.
KWayland connects to it as a client and itself becomes the window manager
for the KDE session: it exposes its own Wayland socket (wayland-0) for
plasmashell/apps and a rootless Xwayland server on :1 for X11 apps.

The X11 socket is pre-bound here and handed to KWin via --xwayland-fd so
X clients can connect before Xwayland finishes starting (same approach as
the linuxserver/docker-webtop KDE image).
"""
import os
import socket

display_env = os.environ.get("DISPLAY", ":1")
display_num = display_env.lstrip(":")
path = f"/tmp/.X11-unix/X{display_num}"

if os.path.exists(path):
    os.remove(path)

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.bind(path)
s.listen(128)

fd = s.fileno()
os.set_inheritable(fd, True)

os.execlp(
    "kwin_wayland",
    "kwin_wayland",
    "--no-lockscreen",
    "--socket", "wayland-0",
    "--xwayland",
    f"--xwayland-display=:{display_num}",
    f"--xwayland-fd={fd}",
)
