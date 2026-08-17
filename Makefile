# --- Konfiguration ---
CONTAINER_NAME = ubuntu-kde-running
PORT         = 3000
SHM_SIZE     = 4gb
CPU_COUNT    = 4
MEMORY_LIMIT = 8g

# --- Standard-Target ---
.PHONY: all
all: clean build-base build-devenv start-devenv

# --- Build-Prozess ---
.PHONY: build
build: build-base

.PHONY: build-all
build-all: build-base build-devenv

.PHONY: build-base
build-base:
	@echo "==> Baue Ubuntu-KDE-Base-Image..."
	docker build -f Dockerfile.base -t sr4l/webtop-ubuntu-kde-base .

.PHONY: build-devenv
build-devenv:
	@echo "==> Baue Ubuntu-KDE-Devenv-Image..."
	docker build -f Dockerfile.devenv -t sr4l/webtop-ubuntu-kde-devenv .

# --- Container starten ---
.PHONY: start
start:
	@echo "==> Starte Container $(CONTAINER_NAME)..."
	docker run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):3000 \
		--shm-size=$(SHM_SIZE) \
		sr4l/webtop-ubuntu-kde-base
	@echo "==> KDE Webtop läuft auf http://localhost:$(PORT) (Login: ubuntu / mypasswd)"

.PHONY: start-devenv
start-devenv:
	@echo "==> Starte Container $(CONTAINER_NAME)..."
	docker run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):3000 \
		--shm-size=$(SHM_SIZE) \
		--cpus=$(CPU_COUNT) \
		--memory=$(MEMORY_LIMIT) \
		--device /dev/dri:/dev/dri \
		sr4l/webtop-ubuntu-kde-devenv
	@echo "==> KDE Webtop läuft auf http://localhost:$(PORT) (Login: ubuntu / mypasswd)"

# --- Container stoppen ---
.PHONY: stop
stop:
	@echo "==> Stoppe Container $(CONTAINER_NAME)..."
	-docker stop $(CONTAINER_NAME)

# --- Bereinigung ---
.PHONY: clean
clean: stop
	@echo "==> Entferne Container $(CONTAINER_NAME)..."
	-docker rm $(CONTAINER_NAME)

# --- Logs anzeigen ---
.PHONY: logs
logs:
	docker logs -f $(CONTAINER_NAME)

# --- Image exportieren/importieren ---
.PHONY: export-image
export-image:
	@echo "==> Exportiere sr4l/webtop-ubuntu-kde-devenv Image..."
	docker save sr4l/webtop-ubuntu-kde-devenv -o sr4l-webtop-ubuntu-kde-devenv.tar

.PHONY: import-image
import-image:
	@echo "==> Importiere sr4l/webtop-ubuntu-kde-devenv Image..."
	docker load -i sr4l-webtop-ubuntu-kde-devenv.tar

# --- Push to Docker Hub ---
.PHONY: push-base
push-base:
	@echo "==> Pushe sr4l/webtop-ubuntu-kde-base zu Docker Hub..."
	docker push sr4l/webtop-ubuntu-kde-base:latest

.PHONY: push-devenv
push-devenv:
	@echo "==> Pushe sr4l/webtop-ubuntu-kde-devenv zu Docker Hub..."
	docker push sr4l/webtop-ubuntu-kde-devenv:latest

.PHONY: push
push: push-base push-devenv

