.PHONY: help setup build up down restart logs status clean

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Run initial setup (prerequisites, .env, game data check)
	@./setup.sh

build: ## Build Docker images
	docker compose build

up: ## Start all services in background
	docker compose up -d

down: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## Tail logs from all services
	docker compose logs -f

status: ## Show service status and health
	docker compose ps

clean: ## Remove containers, volumes, and built images
	docker compose down -v --rmi local
