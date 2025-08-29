# Yocto Raspberry Pi with Bootgen Makefile
# Automated build system for Yocto project

# Configuration
POKY_BRANCH := kirkstone
META_RASPI_BRANCH := kirkstone
BUILD_DIR := build
SOURCES_DIR := sources
MACHINE_QEMU := qemuarm64
MACHINE_RPI := raspberrypi4-64

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help setup setup-sources setup-build build build-custom build-rpi test clean clean-all install-deps check-deps fix-userns

# Default target
all: check-deps setup build test

help:
	@echo "$(BLUE)Yocto Raspberry Pi with Bootgen - Automated Build System$(NC)"
	@echo ""
	@echo "$(GREEN)Available Targets:$(NC)"
	@echo "  $(YELLOW)help$(NC)          - Show this help message"
	@echo "  $(YELLOW)install-deps$(NC)  - Install system dependencies"
	@echo "  $(YELLOW)check-deps$(NC)    - Check if dependencies are installed"
	@echo "  $(YELLOW)fix-userns$(NC)    - Fix user namespace issues for BitBake"
	@echo "  $(YELLOW)setup$(NC)         - Initialize project (clone sources + configure build env)"
	@echo "  $(YELLOW)setup-sources$(NC) - Clone Yocto sources and dependencies"
	@echo "  $(YELLOW)setup-build$(NC)   - Configure build environment"
	@echo "  $(YELLOW)build$(NC)         - Build base image (core-image-minimal)"
	@echo "  $(YELLOW)build-custom$(NC)  - Build custom image (raspberrypi-bootgen-image)"
	@echo "  $(YELLOW)build-rpi$(NC)     - Build Raspberry Pi 4 image"
	@echo "  $(YELLOW)test$(NC)          - Test image in QEMU"
	@echo "  $(YELLOW)clean$(NC)         - Clean build files"
	@echo "  $(YELLOW)clean-all$(NC)     - Clean all files (including sources)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make install-deps  # Install dependencies (once only)"
	@echo "  make all          # Complete build and test workflow"
	@echo ""
	@echo "$(GREEN)Example Workflow:$(NC)"
	@echo "  make setup        # Initialize project"
	@echo "  make build        # Build QEMU image"
	@echo "  make test         # Test image"
	@echo "  make build-rpi    # Build Raspberry Pi image"

install-deps:
	@echo "$(BLUE)Installing system dependencies...$(NC)"
	sudo apt-get update
	@echo "$(YELLOW)Installing core build tools...$(NC)"
	sudo apt-get install -y \
		gawk wget git diffstat unzip texinfo gcc build-essential \
		chrpath socat cpio python3 python3-pip python3-pexpect \
		xz-utils debianutils iputils-ping python3-git python3-jinja2 \
		xterm python3-subunit mesa-common-dev zstd lz4 file
	@echo "$(YELLOW)Configuring user namespaces for BitBake...$(NC)"
	@if [ -f /etc/apparmor.d/unprivileged_userns ]; then \
		echo "$(BLUE)Disabling AppArmor unprivileged user namespaces restriction...$(NC)"; \
		sudo apparmor_parser -R /etc/apparmor.d/unprivileged_userns || true; \
	else \
		echo "$(GREEN)AppArmor unprivileged_userns profile not found, skipping...$(NC)"; \
	fi
	@echo "$(BLUE)Enabling unprivileged user namespaces...$(NC)"
	sudo sysctl -w kernel.unprivileged_userns_clone=1 || true
	echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a /etc/sysctl.conf > /dev/null || true
	@echo "$(GREEN)Dependencies installation completed!$(NC)"

check-deps:
	@echo "$(BLUE)Checking system dependencies...$(NC)"
	@command -v git >/dev/null 2>&1 || { echo "$(RED)Error: git is required$(NC)"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "$(RED)Error: python3 is required$(NC)"; exit 1; }
	@command -v gcc >/dev/null 2>&1 || { echo "$(RED)Error: gcc is required$(NC)"; exit 1; }
	@command -v lz4 >/dev/null 2>&1 || { echo "$(RED)Error: lz4 is required, run 'make install-deps'$(NC)"; exit 1; }
	@echo "$(GREEN)Dependencies check passed!$(NC)"

fix-userns:
	@echo "$(BLUE)Fixing user namespace issues for BitBake...$(NC)"
	@echo "$(YELLOW)This will modify system AppArmor and sysctl settings$(NC)"
	@if [ -f /etc/apparmor.d/unprivileged_userns ]; then \
		echo "$(BLUE)Disabling AppArmor unprivileged user namespaces restriction...$(NC)"; \
		sudo apparmor_parser -R /etc/apparmor.d/unprivileged_userns; \
	else \
		echo "$(GREEN)AppArmor unprivileged_userns profile not found, skipping...$(NC)"; \
	fi
	@echo "$(BLUE)Enabling unprivileged user namespaces...$(NC)"
	sudo sysctl -w kernel.unprivileged_userns_clone=1
	echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a /etc/sysctl.conf > /dev/null
	@echo "$(GREEN)User namespace configuration completed!$(NC)"
	@echo "$(YELLOW)You may need to reboot for changes to take full effect$(NC)"

setup: setup-sources setup-build
	@echo "$(GREEN)Project initialization completed!$(NC)"
	@echo "$(YELLOW)Next step: Run 'make build' to start building$(NC)"

setup-sources:
	@echo "$(BLUE)Cloning Yocto sources...$(NC)"
	@if [ ! -d "$(SOURCES_DIR)" ]; then mkdir -p $(SOURCES_DIR); fi
	
	# Clone Poky (Yocto core)
	@if [ ! -d "$(SOURCES_DIR)/poky" ]; then \
		echo "$(YELLOW)Cloning Poky ($(POKY_BRANCH))...$(NC)"; \
		git clone git://git.yoctoproject.org/poky $(SOURCES_DIR)/poky; \
		cd $(SOURCES_DIR)/poky && git checkout $(POKY_BRANCH); \
	else \
		echo "$(GREEN)Poky already exists, skipping clone$(NC)"; \
	fi
	
	# Clone meta-raspberrypi
	@if [ ! -d "$(SOURCES_DIR)/meta-raspberrypi" ]; then \
		echo "$(YELLOW)Cloning meta-raspberrypi ($(META_RASPI_BRANCH))...$(NC)"; \
		git clone -b $(META_RASPI_BRANCH) https://github.com/agherzan/meta-raspberrypi.git $(SOURCES_DIR)/meta-raspberrypi; \
	else \
		echo "$(GREEN)meta-raspberrypi already exists, skipping clone$(NC)"; \
	fi
	
	@echo "$(GREEN)Source cloning completed!$(NC)"

setup-build:
	@echo "$(BLUE)Configuring build environment...$(NC)"
	
	# Check if meta-bootgen layer exists
	@if [ ! -d "meta-bootgen" ]; then \
		echo "$(RED)Error: meta-bootgen layer does not exist!$(NC)"; \
		echo "$(YELLOW)Please ensure meta-bootgen directory is in project root$(NC)"; \
		exit 1; \
	fi
	
	# Initialize build environment
	@if [ ! -d "$(BUILD_DIR)" ]; then \
		echo "$(YELLOW)Initializing build environment...$(NC)"; \
		bash -c "source $(SOURCES_DIR)/poky/oe-init-build-env $(BUILD_DIR)"; \
	fi
	
	# Check if configuration files exist
	@if [ ! -f "$(BUILD_DIR)/conf/local.conf" ] || [ ! -f "$(BUILD_DIR)/conf/bblayers.conf" ]; then \
		echo "$(RED)Error: Build configuration files do not exist!$(NC)"; \
		echo "$(YELLOW)Please manually run: source sources/poky/oe-init-build-env build$(NC)"; \
		exit 1; \
	fi
	
	@echo "$(GREEN)Build environment configuration completed!$(NC)"

build: check-sources
	@echo "$(BLUE)Building base image (core-image-minimal) for $(MACHINE_QEMU)...$(NC)"
	@echo "$(YELLOW)This may take 30-60 minutes, please be patient...$(NC)"
	cd $(BUILD_DIR) && \
	bash -c "source ../sources/poky/oe-init-build-env . && bitbake core-image-minimal"
	@echo "$(GREEN)Base image build completed!$(NC)"
	@echo "$(YELLOW)Image location: $(BUILD_DIR)/tmp/deploy/images/$(MACHINE_QEMU)/$(NC)"

build-custom: check-sources
	@echo "$(BLUE)Building custom image (raspberrypi-bootgen-image) for $(MACHINE_QEMU)...$(NC)"
	@echo "$(YELLOW)This may take 30-60 minutes, please be patient...$(NC)"
	cd $(BUILD_DIR) && \
	bash -c "source ../sources/poky/oe-init-build-env . && bitbake raspberrypi-bootgen-image"
	@echo "$(GREEN)Custom image build completed!$(NC)"
	@echo "$(YELLOW)Image location: $(BUILD_DIR)/tmp/deploy/images/$(MACHINE_QEMU)/$(NC)"

build-rpi: check-sources
	@echo "$(BLUE)Building Raspberry Pi 4 image...$(NC)"
	@echo "$(YELLOW)Switching to MACHINE=$(MACHINE_RPI)$(NC)"
	@echo "$(YELLOW)This may take 30-60 minutes, please be patient...$(NC)"
	cd $(BUILD_DIR) && \
	bash -c "source ../sources/poky/oe-init-build-env . && MACHINE=$(MACHINE_RPI) bitbake core-image-minimal"
	@echo "$(GREEN)Raspberry Pi image build completed!$(NC)"
	@echo "$(YELLOW)Image location: $(BUILD_DIR)/tmp/deploy/images/$(MACHINE_RPI)/$(NC)"
	@echo "$(BLUE)Flash to SD card command:$(NC)"
	@echo "  sudo dd if=$(BUILD_DIR)/tmp/deploy/images/$(MACHINE_RPI)/core-image-minimal-$(MACHINE_RPI).wic.bz2 of=/dev/sdX bs=4M"

test: check-image
	@echo "$(BLUE)Testing image in QEMU...$(NC)"
	@echo "$(YELLOW)Starting QEMU virtual machine (no GUI mode)...$(NC)"
	@echo "$(GREEN)Test bootgen in virtual machine:$(NC)"
	@echo "  bootgen --help"
	@echo "  bootgen --version"
	@echo "$(YELLOW)Exit QEMU: Ctrl+A, X$(NC)"
	cd $(BUILD_DIR) && \
	bash -c "source ../sources/poky/oe-init-build-env . && DISABLE_GUI=1 runqemu $(MACHINE_QEMU) nographic"

# Clean targets
clean:
	@echo "$(BLUE)Cleaning build files...$(NC)"
	@if [ -d "$(BUILD_DIR)" ]; then \
		cd $(BUILD_DIR) && \
		bash -c "source ../sources/poky/oe-init-build-env . && bitbake -c cleanall"; \
		rm -rf tmp sstate-cache; \
	fi
	@echo "$(GREEN)Build files cleanup completed!$(NC)"

clean-all:
	@echo "$(RED)Cleaning all files (including sources)...$(NC)"
	@read -p "Are you sure you want to delete all files? This will remove sources/ and build/ directories [y/N]: " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		rm -rf $(SOURCES_DIR) $(BUILD_DIR); \
		echo "$(GREEN)All files cleanup completed!$(NC)"; \
	else \
		echo "$(YELLOW)Cleanup operation cancelled$(NC)"; \
	fi

# Helper check targets
check-sources:
	@if [ ! -d "$(SOURCES_DIR)/poky" ]; then \
		echo "$(RED)Error: Poky sources do not exist! Run 'make setup-sources'$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d "$(BUILD_DIR)" ]; then \
		echo "$(RED)Error: Build directory does not exist! Run 'make setup-build'$(NC)"; \
		exit 1; \
	fi

check-image:
	@if [ ! -f "$(BUILD_DIR)/tmp/deploy/images/$(MACHINE_QEMU)/core-image-minimal-$(MACHINE_QEMU).ext4" ]; then \
		echo "$(RED)Error: Image file does not exist! Run 'make build' to build image first$(NC)"; \
		exit 1; \
	fi

# Show build status
status:
	@echo "$(BLUE)Project Status:$(NC)"
	@echo "Current directory: $(shell pwd)"
	@echo "Sources directory: $(if $(shell test -d $(SOURCES_DIR) && echo 1),$(GREEN)exists$(NC),$(RED)does not exist$(NC))"
	@echo "Build directory: $(if $(shell test -d $(BUILD_DIR) && echo 1),$(GREEN)exists$(NC),$(RED)does not exist$(NC))"
	@echo "Poky: $(if $(shell test -d $(SOURCES_DIR)/poky && echo 1),$(GREEN)cloned$(NC),$(RED)not cloned$(NC))"
	@echo "meta-raspberrypi: $(if $(shell test -d $(SOURCES_DIR)/meta-raspberrypi && echo 1),$(GREEN)cloned$(NC),$(RED)not cloned$(NC))"
	@echo "meta-bootgen: $(if $(shell test -d meta-bootgen && echo 1),$(GREEN)exists$(NC),$(RED)does not exist$(NC))"
	@if [ -d "$(BUILD_DIR)" ]; then \
		echo "Available images:"; \
		find $(BUILD_DIR)/tmp/deploy/images -name "*.ext4" 2>/dev/null || echo "  No available images"; \
	fi

# Development helper targets
dev-shell:
	@echo "$(BLUE)Entering development shell...$(NC)"
	cd $(BUILD_DIR) && \
	bash -c "source ../sources/poky/oe-init-build-env . && bitbake -c devshell bootgen"

bootgen-only:
	@echo "$(BLUE)Building bootgen tool only...$(NC)"
	cd $(BUILD_DIR) && \
	bash -c "source ../sources/poky/oe-init-build-env . && bitbake bootgen"

bootgen-clean:
	@echo "$(BLUE)Cleaning bootgen build...$(NC)"
	cd $(BUILD_DIR) && \
	bash -c "source ../sources/poky/oe-init-build-env . && bitbake -c cleanall bootgen"

# Information display targets
info:
	@echo "$(BLUE)Project Information:$(NC)"
	@echo "Project name: Yocto Raspberry Pi with Bootgen"
	@echo "Yocto version: $(POKY_BRANCH)"
	@echo "Target machines: $(MACHINE_QEMU) (QEMU), $(MACHINE_RPI) (Raspberry Pi)"
	@echo "Build directory: $(BUILD_DIR)"
	@echo "Sources directory: $(SOURCES_DIR)"
	@echo ""
	@echo "$(GREEN)Main Components:$(NC)"
	@echo "- Poky (Yocto core)"
	@echo "- meta-raspberrypi (Raspberry Pi support)"
	@echo "- meta-bootgen (Custom Bootgen layer)"