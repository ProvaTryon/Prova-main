# Fashion Platform - Development Commands (Cross-Platform)

# Default target
.DEFAULT_GOAL := help

# Variables
BACKEND_DIR = backend
FRONTEND_DIR = frontend

# Detect OS
ifeq ($(OS),Windows_NT)
    detected_OS := Windows
    RM := del /Q
    RMDIR := rmdir /S /Q
    MKDIR := mkdir
    SEP := \\
    NULL := NUL
    # Windows simple echo commands (no colors for performance)
    GREEN := echo
    YELLOW := echo
    RED := echo
    ECHO := echo
else
    detected_OS := $(shell uname -s)
    RM := rm -f
    RMDIR := rm -rf
    MKDIR := mkdir -p
    SEP := /
    NULL := /dev/null
    # Unix/Linux ANSI colors
    GREEN := echo -e "\033[0;32m"
    YELLOW := echo -e "\033[0;33m"
    RED := echo -e "\033[0;31m"
    ECHO := echo
endif

## Backend Commands
.PHONY: backend-dev
backend-dev: ## Start backend development server
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Starting backend development server...' -ForegroundColor Green"
else
	@echo "\033[0;32mStarting backend development server...\033[0m"
endif
ifeq ($(detected_OS),Windows)
	cd $(BACKEND_DIR) && npm run dev
else
	cd $(BACKEND_DIR) && npm run dev
endif

.PHONY: backend-start
backend-start: ## Start backend production server
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Starting backend production server...' -ForegroundColor Green"
else
	@echo "\033[0;32mStarting backend production server...\033[0m"
endif
	cd $(BACKEND_DIR) && npm start

.PHONY: backend-install
backend-install: ## Install backend dependencies
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Installing backend dependencies...' -ForegroundColor Green"
else
	@echo "\033[0;32mInstalling backend dependencies...\033[0m"
endif
	cd $(BACKEND_DIR) && npm install

.PHONY: backend-test
backend-test: ## Run backend tests
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Running backend tests...' -ForegroundColor Green"
else
	@echo "\033[0;32mRunning backend tests...\033[0m"
endif
	cd $(BACKEND_DIR) && npm test

## Frontend Commands
.PHONY: frontend-dev
frontend-dev: ## Start frontend development server
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Starting frontend development server...' -ForegroundColor Green"
else
	@echo "\033[0;32mStarting frontend development server...\033[0m"
endif
	cd $(FRONTEND_DIR) && npm run dev

.PHONY: frontend-install
frontend-install: ## Install frontend dependencies
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Installing frontend dependencies...' -ForegroundColor Green"
else
	@echo "\033[0;32mInstalling frontend dependencies...\033[0m"
endif
	cd $(FRONTEND_DIR) && npm install

## Combined Commands
.PHONY: install
install: backend-install frontend-install ## Install all dependencies
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'All dependencies installed!' -ForegroundColor Green"
else
	@echo "\033[0;32mAll dependencies installed!\033[0m"
endif

.PHONY: dev
dev: backend-dev frontend-dev ## Start all development servers

.PHONY: clean
clean: ## Clean node_modules and package-lock files
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Cleaning project...' -ForegroundColor Yellow"
	@if exist "$(BACKEND_DIR)$(SEP)node_modules" ( rmdir /S /Q "$(BACKEND_DIR)$(SEP)node_modules" )
	@if exist "$(BACKEND_DIR)$(SEP)package-lock.json" ( del "$(BACKEND_DIR)$(SEP)package-lock.json" )
	@if exist "$(FRONTEND_DIR)$(SEP)node_modules" ( rmdir /S /Q "$(FRONTEND_DIR)$(SEP)node_modules" )
	@if exist "$(FRONTEND_DIR)$(SEP)package-lock.json" ( del "$(FRONTEND_DIR)$(SEP)package-lock.json" )
	@powershell -Command "Write-Host 'Clean complete!' -ForegroundColor Green"
else
	@echo "\033[0;33mCleaning project...\033[0m"
	$(RMDIR) $(BACKEND_DIR)/node_modules $(BACKEND_DIR)/package-lock.json
	$(RMDIR) $(FRONTEND_DIR)/node_modules $(FRONTEND_DIR)/package-lock.json
	@echo "\033[0;32mClean complete!\033[0m"
endif

.PHONY: setup
setup: ## Setup development environment
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Setting up development environment...' -ForegroundColor Green; Write-Host 'Detected OS: $(detected_OS)'; Write-Host 'Make sure you have Node.js and npm installed'; Write-Host 'Run ''make install'' to install dependencies'; Write-Host 'Setup instructions displayed!' -ForegroundColor Green"
else
	@echo "\033[0;32mSetting up development environment...\033[0m"
	@echo "Detected OS: $(detected_OS)"
	@echo "Make sure you have Node.js and npm installed"
	@echo "Run 'make install' to install dependencies"
	@echo "\033[0;32mSetup instructions displayed!\033[0m"
endif

.PHONY: status
status: ## Show project status
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Project Status:' -ForegroundColor Green; Write-Host 'OS: $(detected_OS)'; Write-Host 'Backend Directory: $(BACKEND_DIR)'; Write-Host 'Frontend Directory: $(FRONTEND_DIR)'; if (Test-Path '$(BACKEND_DIR)$(SEP)node_modules') { Write-Host 'Backend dependencies: INSTALLED' } else { Write-Host 'Backend dependencies: NOT INSTALLED' }; if (Test-Path '$(FRONTEND_DIR)$(SEP)node_modules') { Write-Host 'Frontend dependencies: INSTALLED' } else { Write-Host 'Frontend dependencies: NOT INSTALLED' }"
else
	@echo "\033[0;32mProject Status:\033[0m"
	@echo "OS: $(detected_OS)"
	@echo "Backend Directory: $(BACKEND_DIR)"
	@echo "Frontend Directory: $(FRONTEND_DIR)"
	@if [ -d "$(BACKEND_DIR)/node_modules" ]; then echo "Backend dependencies: INSTALLED"; else echo "Backend dependencies: NOT INSTALLED"; fi
	@if [ -d "$(FRONTEND_DIR)/node_modules" ]; then echo "Frontend dependencies: INSTALLED"; else echo "Frontend dependencies: NOT INSTALLED"; fi
endif

.PHONY: help
help: ## Show this help message
ifeq ($(detected_OS),Windows)
	@powershell -Command "Write-Host 'Fashion Platform - Available Commands:' -ForegroundColor Green; Write-Host 'Detected OS: $(detected_OS)'; Write-Host ''; Write-Host '  backend-dev          Start backend development server' -ForegroundColor Yellow; Write-Host '  backend-start        Start backend production server' -ForegroundColor Yellow; Write-Host '  backend-install      Install backend dependencies' -ForegroundColor Yellow; Write-Host '  backend-test         Run backend tests' -ForegroundColor Yellow; Write-Host '  frontend-dev         Start frontend development server' -ForegroundColor Yellow; Write-Host '  frontend-install     Install frontend dependencies' -ForegroundColor Yellow; Write-Host '  install              Install all dependencies' -ForegroundColor Yellow; Write-Host '  dev                  Start all development servers' -ForegroundColor Yellow; Write-Host '  clean                Clean node_modules and package-lock files' -ForegroundColor Yellow; Write-Host '  setup                Setup development environment' -ForegroundColor Yellow; Write-Host '  status               Show project status' -ForegroundColor Yellow; Write-Host '  help                 Show this help message' -ForegroundColor Yellow; Write-Host ''; Write-Host 'Usage:' -ForegroundColor Green; Write-Host '  make [command]'; Write-Host ''; Write-Host 'Examples:' -ForegroundColor Green; Write-Host '  make backend-dev    # Start backend development server'; Write-Host '  make dev           # Same as backend-dev (shortcut)'; Write-Host '  make install       # Install all dependencies'; Write-Host '  make status        # Show project status'; Write-Host '  make help          # Show this help'"
else
	@echo "\033[0;32mFashion Platform - Available Commands:\033[0m"
	@echo "Detected OS: $(detected_OS)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;33m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "\033[0;32mUsage:\033[0m"
	@echo "  make [command]"
	@echo ""
	@echo "\033[0;32mExamples:\033[0m"
	@echo "  make backend-dev    # Start backend development server"
	@echo "  make dev           # Same as backend-dev (shortcut)"
	@echo "  make install       # Install all dependencies"
	@echo "  make status        # Show project status"
	@echo "  make help          # Show this help"
endif