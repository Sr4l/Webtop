# --- Konfiguration ---
IMAGE_NAME   = ubuntu-kde-managed
TAG          = 26.04
CONTAINER_NAME = ubuntu-kde-running
PORT         = 3000
SHM_SIZE     = 2gb

# --- Standard-Target ---
.PHONY: all
all: clean build start

# --- Build-Prozess ---
.PHONY: build
build:
	@echo "==> Baue Ubuntu 26.04 Docker-Image $(IMAGE_NAME):$(TAG)..."
	docker build -t $(IMAGE_NAME):$(TAG) .

# --- Container starten ---
.PHONY: start
start:
	@echo "==> Starte Container $(CONTAINER_NAME)..."
	docker run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):3000 \
		--shm-size=$(SHM_SIZE) \
		--device /dev/dri:/dev/dri \
		--device /dev/snd:/dev/snd \
		$(IMAGE_NAME):$(TAG)
	@echo "==> Selkies läuft auf http://localhost:$(PORT)"

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
