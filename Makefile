.PHONY: setup test lint format run clean help

# Use uv as the modern 2026 standard if available, otherwise fallback to python
PYTHON := $(shell which uv > /dev/null && echo "uv run" || echo "python3")
PIP := $(shell which uv > /dev/null && echo "uv pip" || echo "pip")

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Setup environment and install dependencies
	@echo "Setting up environment..."
	$(PIP) install -e ".[dev]"

test: ## Run tests
	@echo "Running tests..."
	$(PYTHON) -m pytest tests/

lint: ## Run linter (Ruff)
	@echo "Running linter..."
	$(PYTHON) -m ruff check .

format: ## Auto-format code (Ruff)
	@echo "Formatting code..."
	$(PYTHON) -m ruff format .

run: ## Run the application
	@echo "Running application..."
	$(PYTHON) -m src.project.main

clean: ## Clean up cache and build artifacts
	@echo "Cleaning up..."
	find . -type d -name "__pycache__" -exec rm -rf {} +
	rm -rf .pytest_cache .ruff_cache .mypy_cache build/ dist/
