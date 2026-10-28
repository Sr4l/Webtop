# kde-webtop

KDE Plasma webtop streamed in the browser via [Selkies](https://github.com/selkies-project/selkies). Runs KWin nested on top of the pixelflux capture compositor inside a Docker container.

## Architecture

```
Browser ←→ Selkies (WebSocket/WebRTC) ←→ pixelflux (wayland-1) ←→ nested KWin (wayland-0) ←→ KDE Plasma
```

- **Selkies** streams the desktop to the browser over WebSockets
- **pixelflux** acts as the headless capture compositor on `wayland-1`
- **KWin** connects as a Wayland client to pixelflux, exposing `wayland-0` for plasmashell/apps
- **Xwayland** runs rootless on `:1` for X11 app support

## Quick Start

### Option 1: Pre-built image from GitHub (recommended)

```bash
# Pull and run the latest image
docker run -d \
  --name ubuntu-kde-running \
  -p 3000:3000 \
  --shm-size=2gb \
sr4l/webtop-ubuntu-kde-devenv:latest
```

Access the desktop at `http://localhost:3000`.

### Option 2: Build locally

```bash
# Build base image
make build-base

# Build full development environment
make build-devenv

# Start the container
make start-devenv
```

Access the desktop at `http://localhost:3000`.

### Makefile Targets

| Target | Description |
|---|---|
| `make all` | Full build + start (default) |
| `make build-base` | Build base image only |
| `make build-devenv` | Build devenv image |
| `make start` | Start container from base image |
| `make start-devenv` | Start container from devenv image |
| `make stop` | Stop running container |
| `make clean` | Stop and remove container |
| `make logs` | Follow container logs |
| `make push` | Push both images to Docker Hub |
| `make push-base` | Push only base image to Docker Hub |
| `make push-devenv` | Push only devenv image to Docker Hub |

## Configuration

Settable via Makefile variables:

- `PORT` — Host port to expose (default: `3000`)
- `CONTAINER_NAME` — Container name (default: `ubuntu-kde-running`)
- `SHM_SIZE` — Shared memory size (default: `2gb`)

## Push to Docker Hub

After building, push your images to Docker Hub:

```bash
make push
```

This pushes both `sr4l/webtop-ubuntu-kde-base` and `sr4l/webtop-ubuntu-kde-devenv`.

You can also push individual images:

```bash
make push-base
make push-devenv
```

## Stack

- **Base**: Ubuntu 26.04
- **Desktop**: KDE Plasma (Wayland session)
- **Streaming**: Selkies (pixelflux/pcmflux, WebSockets mode, JPEG encoder)
- **Audio**: PipeWire + WirePlumber + null sink
- **Runtime**: supervisord (dbus, pipewire, selkies, kwin, plasmashell, …)

## Desktop launchers

The development image ships desktop launchers for [OpenCode](https://opencode.ai) (`opencode`),
[Pi](https://github.com/earendil-works/pi) (`pi`) and a terminal. OpenCode and Pi appear in the
Kickoff application menu under **Development**; all three are available as icons on the Plasma
desktop. The agents start in a maximized Konsole window in `/home/ubuntu`.
