# ubuntu-kde-webtop

Ubuntu 26.04 + KDE Plasma webtop streamed in the browser via [Selkies](https://github.com/selkies-project/selkies). Runs KWin nested on top of the pixelflux capture compositor inside a Docker container.

## Architecture

```
Browser ←→ Selkies (WebSocket/WebRTC) ←→ pixelflux (wayland-1) ←→ nested KWin (wayland-0) ←→ KDE Plasma
```

- **Selkies** streams the desktop to the browser over WebSockets
- **pixelflux** acts as the headless capture compositor on `wayland-1`
- **KWin** connects as a Wayland client to pixelflux, exposing `wayland-0` for plasmashell/apps
- **Xwayland** runs rootless on `:1` for X11 app support

## Quick Start

```bash
make
```

This builds the base image and starts the container. Access the desktop at `http://localhost:3000` (login: `ubuntu` / `mypasswd`).

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

## Configuration

Settable via Makefile variables:

- `PORT` — Host port to expose (default: `3000`)
- `CONTAINER_NAME` — Container name (default: `ubuntu-kde-running`)
- `SHM_SIZE` — Shared memory size (default: `2gb`)

## Stack

- **Base**: Ubuntu 26.04
- **Desktop**: KDE Plasma (Wayland session)
- **Streaming**: Selkies (pixelflux/pcmflux, WebSockets mode, JPEG encoder)
- **Audio**: PipeWire + WirePlumber + null sink
- **Runtime**: supervisord (dbus, pipewire, selkies, kwin, plasmashell, …)