.PHONY: help check-dotnet lint format format-fix build test ci tools setup

SLN := core-dotnet.sln
CONFIG ?= Release

# Prefer the Microsoft dotnet host on macOS when it includes the net8.0 runtime.
DOTNET_DIR := $(firstword $(wildcard /usr/local/share/dotnet) $(HOME)/.dotnet)
ifneq ($(DOTNET_DIR),)
export PATH := $(DOTNET_DIR):$(PATH)
endif
DOTNET ?= dotnet

# Match .github/workflows/*.yml (SDK 10 builds net8.0; tests need the net8.0 runtime).
DOTNET_SDK_CHANNEL ?= 10.0
DOTNET_RUNTIME_CHANNEL ?= 8.0
DOTNET_INSTALL_DIR ?= $(HOME)/.dotnet

.DEFAULT_GOAL := help

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  lint        Build with StyleCop (same as CI lint job)"
	@echo "  format      Verify formatting (dotnet format --verify-no-changes)"
	@echo "  format-fix  Apply formatting fixes locally"
	@echo "  build       dotnet build ($(CONFIG))"
	@echo "  test        Build and run tests"
	@echo "  ci          format, lint, and test"
	@echo "  tools       Install .NET SDK $(DOTNET_SDK_CHANNEL) and runtime $(DOTNET_RUNTIME_CHANNEL)"
	@echo "  setup       Alias for tools"
	@echo ""
	@echo "First-time setup: make tools"
	@echo "Then add to your shell: export PATH=\"$(DOTNET_INSTALL_DIR):\$$PATH\""

check-dotnet:
	@command -v $(DOTNET) >/dev/null 2>&1 || { \
		echo "$(DOTNET) not found; install with: make tools"; \
		exit 1; \
	}
	@$(DOTNET) --list-runtimes 2>/dev/null | grep -q 'Microsoft.NETCore.App 8\.' || { \
		echo "Microsoft.NETCore.App 8.x runtime not found (required for net8.0 tests)."; \
		echo "Install with: make tools"; \
		echo "On macOS with Homebrew dotnet 10 only, use: export PATH=\"/usr/local/share/dotnet:\$$PATH\""; \
		exit 1; \
	}

lint: build

format: check-dotnet
	$(DOTNET) format $(SLN) --verify-no-changes

format-fix: check-dotnet
	$(DOTNET) format $(SLN)

build: check-dotnet
	$(DOTNET) build $(SLN) -c $(CONFIG)

test: build
	$(DOTNET) test $(SLN) -c $(CONFIG) --no-build

ci: format lint test

tools setup:
	@echo "Installing .NET SDK $(DOTNET_SDK_CHANNEL) and runtime $(DOTNET_RUNTIME_CHANNEL) to $(DOTNET_INSTALL_DIR)..."
	@curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
	@chmod +x /tmp/dotnet-install.sh
	@/tmp/dotnet-install.sh --channel $(DOTNET_SDK_CHANNEL) --install-dir $(DOTNET_INSTALL_DIR)
	@/tmp/dotnet-install.sh --runtime dotnet --channel $(DOTNET_RUNTIME_CHANNEL) --install-dir $(DOTNET_INSTALL_DIR)
	@echo ""
	@echo "Done. Add to ~/.zshrc or ~/.bashrc:"
	@echo "  export PATH=\"$(DOTNET_INSTALL_DIR):\$$PATH\""
