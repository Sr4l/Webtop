# --- Konfiguration ---
CONTAINER_NAME = ubuntu-kde-running
PORT         = 3000
SHM_SIZE     = 2gb

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
	docker build -f Dockerfile.base -t ubuntu-kde-base .

.PHONY: build-devenv
build-devenv:
	@echo "==> Baue Ubuntu-KDE-Devenv-Image..."
	docker build -f Dockerfile.devenv -t ubuntu-kde-devenv .

# --- Container starten ---
.PHONY: start
start:
	@echo "==> Starte Container $(CONTAINER_NAME)..."
	docker run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):3000 \
		--shm-size=$(SHM_SIZE) \
		ubuntu-kde-base
	@echo "==> KDE Webtop läuft auf http://localhost:$(PORT) (Login: ubuntu / mypasswd)"

.PHONY: start-devenv
start-devenv:
	@echo "==> Starte Container $(CONTAINER_NAME)..."
	docker run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):3000 \
		--shm-size=$(SHM_SIZE) \
		ubuntu-kde-devenv
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
	@echo "==> Exportiere ubuntu-kde-devenv Image..."
	docker save ubuntu-kde-devenv -o ubuntu-kde-devenv.tar

.PHONY: import-image
import-image:
	@echo "==> Importiere ubuntu-kde-devenv Image..."
	docker load -i ubuntu-kde-devenv.tar

