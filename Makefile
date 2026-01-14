.PHONY: help build up down restart shell nvim exec logs clean backup restore prune status inspect setup-x11 clone-nvim

.DEFAULT_GOAL := help

# Variables
COMPOSE_FILE := docker-compose.yml
IMAGE_NAME := alpine-dev
CONTAINER_NAME := alpine-dev-workspace
BACKUP_DIR := ./backups
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)
NVIM_REPO := git@github.com:willtrigo/nvim.config.git

help: ## Display available commands
	@echo "Alpine Development Environment - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	@echo "Building Docker image..."
	@docker-compose build --no-cache

up: setup-x11 ## Start the container in detached mode
	@echo "Starting container..."
	@docker-compose up -d
	@echo "Container started. Use 'make shell' to access."

down: ## Stop and remove the container
	@echo "Stopping container..."
	@docker-compose down

restart: down up ## Restart the container

shell: ## Open an interactive shell in the container
	@echo "Opening shell..."
	@docker-compose exec alpine-dev zsh

bash: ## Open bash shell (alternative to zsh)
	@echo "Opening bash shell..."
	@docker-compose exec alpine-dev bash

nvim: ## Start Neovim in the container
	@echo "Starting Neovim..."
	@docker-compose exec alpine-dev nvim

exec: ## Execute a command in the container (usage: make exec CMD="command")
	@if [ -z "$(CMD)" ]; then \
		echo "Error: CMD not specified"; \
		echo "Usage: make exec CMD=\"your command here\""; \
		exit 1; \
	fi
	@docker-compose exec alpine-dev $(CMD)

logs: ## View container logs
	@docker-compose logs -f alpine-dev

clean: ## Stop container and remove volumes (⚠️  WARNING: Deletes data!)
	docker-compose down -v;

backup: ## Backup all volumes
	@echo "Creating backup..."
	@mkdir -p $(BACKUP_DIR)
	@docker run --rm \
		-v alpine-dev-workspace:/source \
		-v $(PWD)/$(BACKUP_DIR):/backup \
		alpine:3.19 \
		tar czf /backup/workspace-$(TIMESTAMP).tar.gz -C /source .
	@docker run --rm \
		-v alpine-dev-nvim-config:/source \
		-v $(PWD)/$(BACKUP_DIR):/backup \
		alpine:3.19 \
		tar czf /backup/nvim-config-$(TIMESTAMP).tar.gz -C /source .
	@docker run --rm \
		-v alpine-dev-home-data:/source \
		-v $(PWD)/$(BACKUP_DIR):/backup \
		alpine:3.19 \
		tar czf /backup/home-data-$(TIMESTAMP).tar.gz -C /source .
	@echo "Backup completed in $(BACKUP_DIR)/"

restore: ## Restore workspace from backup (usage: make restore BACKUP_FILE=backup.tar.gz)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Error: BACKUP_FILE not specified"; \
		echo "Usage: make restore BACKUP_FILE=workspace-20240101_120000.tar.gz"; \
		exit 1; \
	fi
	@echo "Restoring from $(BACKUP_FILE)..."
	@docker run --rm \
		-v alpine-dev-workspace:/target \
		-v $(PWD)/$(BACKUP_DIR):/backup \
		alpine:3.19 \
		tar xzf /backup/$(BACKUP_FILE) -C /target
	@echo "Restore completed."

prune: ## Remove unused Docker resources
	@echo "Pruning unused Docker resources..."
	@docker system prune -f
	@echo "Prune completed."

status: ## Show container and volume status
	@echo "Container Status:"
	@docker-compose ps
	@echo ""
	@echo "Volume Status:"
	@docker volume ls | grep alpine-dev || echo "No alpine-dev volumes found"

inspect: ## Inspect volumes
	@echo "Workspace Volume:"
	@docker volume inspect alpine-dev-workspace 2>/dev/null || echo "Volume not found"
	@echo ""
	@echo "Neovim Config Volume:"
	@docker volume inspect alpine-dev-nvim-config 2>/dev/null || echo "Volume not found"
	@echo ""
	@echo "Home Data Volume:"
	@docker volume inspect alpine-dev-home-data 2>/dev/null || echo "Volume not found"

setup-x11: ## Setup X11 forwarding for GUI applications
	@echo "Setting up X11 forwarding..."
	@xhost +local:docker > /dev/null 2>&1 || echo "Warning: xhost not available or X11 not running"
	@touch ~/.Xauthority || true

clone-nvim: ## Clone Neovim configuration repository into container
	@echo "Cloning Neovim configuration..."
	@docker-compose exec alpine-dev bash -c '\
		if [ -d ~/.config/nvim/.git ]; then \
			echo "Neovim config already exists. Updating..."; \
			cd ~/.config/nvim && git pull; \
		else \
			echo "Cloning Neovim config..."; \
			rm -rf ~/.config/nvim && \
			git clone $(NVIM_REPO) ~/.config/nvim; \
		fi'
	@echo "Neovim configuration cloned/updated."

install: build up clone-nvim ## Complete installation: build, start, and clone nvim config
	@echo "Installation complete!"
	@echo "Run 'make shell' to access the environment."

rebuild: down build up ## Rebuild and restart container

gui: setup-x11 ## Start GUI session (terminator + openbox)
	@echo "Starting GUI session..."
	@docker-compose exec alpine-dev startx

attach: ## Attach to running container
	@docker attach $(CONTAINER_NAME)

update-packages: ## Update all system packages in container
	@echo "Updating packages..."
	@docker-compose exec alpine-dev sudo apk update
	@docker-compose exec alpine-dev sudo apk upgrade
	@echo "Packages updated."

list-installed: ## List all installed packages
	@docker-compose exec alpine-dev apk list --installed

ssh-keygen: ## Generate SSH key in container
	@echo "Generating SSH key..."
	@docker-compose exec alpine-dev ssh-keygen -t ed25519 -C "dande-je@student.42sp.org.br"

size: ## Show image and container sizes
	@echo "Image size:"
	@docker images $(IMAGE_NAME):latest --format "{{.Size}}"
	@echo ""
	@echo "Container size:"
	@docker ps -s --filter name=$(CONTAINER_NAME) --format "{{.Size}}"