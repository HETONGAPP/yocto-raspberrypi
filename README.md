# Yocto Raspberry Pi with Bootgen Tool

This project demonstrates how to build a bootable Linux firmware image for Raspberry Pi using Yocto, including the Xilinx Bootgen tool, with support for both real hardware and QEMU virtual machine testing.

## 🎯 Project Goals

- ✅ Compile bootable Linux firmware image for Raspberry Pi
- ✅ Add new meta-bootgen layer containing Bootgen tool recipe
- ✅ Compile Xilinx Bootgen tool (version 2019.2) for target
- ✅ Add Bootgen tool to firmware image
- ✅ Support QEMU virtual machine testing

## 📋 System Requirements

### Hardware Requirements
- **Disk Space**: At least 50GB available space
- **Memory**: At least 8GB RAM (16GB recommended)
- **CPU**: Multi-core processor (4+ cores recommended)

### Software Dependencies
```bash
# Ubuntu/Debian systems
sudo apt-get update
sudo apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool lz4
```

## 🚀 Quick Start

### Automated Build (Recommended)
```bash
# Clone project
git clone <your-repo-url> yocto-raspberrypi
cd yocto-raspberrypi

# Use Makefile for automated build
make setup          # Initialize environment
make build          # Build base image
make build-custom   # Build custom image
make test           # Test in QEMU

# Or complete all steps at once
make all
```

### Manual Build
```bash
# 1. Clone project and dependencies
git clone git://git.yoctoproject.org/poky sources/poky
cd sources/poky && git checkout kirkstone && cd ../..
git clone -b kirkstone https://github.com/agherzan/meta-raspberrypi.git sources/meta-raspberrypi

# 2. Initialize build environment
source sources/poky/oe-init-build-env build

# 3. Build image
bitbake core-image-minimal
# Or build custom image
bitbake raspberrypi-bootgen-image
```

## 📁 Project Structure

```
yocto-raspberrypi/
├── Makefile                    # Automated build scripts
├── README.md                   # This file
├── sources/                    # Source code directory
│   ├── poky/                   # Yocto core
│   └── meta-raspberrypi/       # Raspberry Pi support layer
├── meta-bootgen/               # Custom Bootgen layer
│   ├── conf/
│   │   └── layer.conf          # Layer configuration
│   ├── recipes-devtools/
│   │   └── bootgen/
│   │       ├── bootgen_2019.2.bb    # Bootgen recipe
│   │       └── files/
│   │           └── bootgen-2019.2.tar.gz  # Source package
│   └── recipes-core/
│       └── images/
│           └── raspberrypi-bootgen-image.bb  # Custom image
└── build/                      # Build directory
    ├── conf/
    │   ├── local.conf          # Local configuration
    │   └── bblayers.conf       # Layer configuration
    └── tmp/                    # Build temporary files
```

## 🔧 Configuration Details

### meta-bootgen Layer

#### 1. Layer Configuration (`meta-bootgen/conf/layer.conf`)
```bitbake
BBPATH .= ":${LAYERDIR}"
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb ${LAYERDIR}/recipes-*/*/*.bbappend"
BBFILE_COLLECTIONS += "meta-bootgen"
BBFILE_PATTERN_meta-bootgen = "^${LAYERDIR}/"
BBFILE_PRIORITY_meta-bootgen = "6"
LAYERDEPENDS_meta-bootgen = "core"
LAYERSERIES_COMPAT_meta-bootgen = "kirkstone"
```

#### 2. Bootgen Recipe (`recipes-devtools/bootgen/bootgen_2019.2.bb`)
- **Source**: Local `bootgen-2019.2.tar.gz` file
- **Dependencies**: OpenSSL library
- **Cross-compilation**: Supports ARM64 architecture
- **License**: MIT

#### 3. Custom Image (`recipes-core/images/raspberrypi-bootgen-image.bb`)
- **Base**: core-image
- **Includes**: bootgen tool + SSH server
- **Features**: Debug tools + development convenience features

### Build Configuration

#### Key local.conf Settings
```bitbake
# Target machine
MACHINE ??= "qemuarm64"        # QEMU virtual machine
# MACHINE ??= "raspberrypi4-64"  # Raspberry Pi 4

# Package manager
PACKAGE_CLASSES ?= "package_ipk"

# Add bootgen to all images
IMAGE_INSTALL:append = " bootgen"

# Enable debug features
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
```

## 🎮 Usage Guide

### 1. Build Target Images

#### QEMU Virtual Machine (Testing)
```bash
# Set up environment
source sources/poky/oe-init-build-env build

# Build QEMU image
bitbake core-image-minimal
```

#### Raspberry Pi 4 (Deployment)
```bash
# Set up environment
source sources/poky/oe-init-build-env build

# Modify MACHINE in local.conf
# MACHINE ??= "raspberrypi4-64"

# Build Raspberry Pi image
bitbake core-image-minimal
```

### 2. Test Images

#### QEMU Virtual Machine Testing
```bash
# Start QEMU (no GUI)
DISABLE_GUI=1 runqemu qemuarm64

# Test bootgen in virtual machine
root@qemuarm64:~# bootgen --help
root@qemuarm64:~# bootgen --version
```

#### Raspberry Pi Testing
```bash
# Flash to SD card
sudo dd if=tmp/deploy/images/raspberrypi4-64/core-image-minimal-raspberrypi4-64.wic.bz2 of=/dev/sdX bs=4M

# Boot Raspberry Pi, then test
pi@raspberrypi:~$ bootgen --help
```

### 3. Image Options

#### core-image-minimal
- **Features**: Minimal system, fast boot, small size
- **Use Case**: Production deployment
- **Build**: `bitbake core-image-minimal`

#### raspberrypi-bootgen-image
- **Features**: Includes SSH, debug tools, feature-rich
- **Use Case**: Development and testing
- **Build**: `bitbake raspberrypi-bootgen-image`

## 🛠️ Development Guide

### Adding New Tools to Image
```bitbake
# Add to local.conf
IMAGE_INSTALL:append = " your-tool-name"
```

### Modifying Bootgen Recipe
1. Edit `meta-bootgen/recipes-devtools/bootgen/bootgen_2019.2.bb`
2. Clean build: `bitbake -c cleanall bootgen`
3. Rebuild: `bitbake bootgen`

### Creating New Image Recipe
```bitbake
# Create new file in meta-bootgen/recipes-core/images/
inherit core-image
IMAGE_INSTALL += "bootgen your-packages"
```

## 🚨 Troubleshooting

### Common Issues

#### 1. User Namespace Error
```bash
# Error: User namespaces are not usable by BitBake
sudo sysctl -w kernel.unprivileged_userns_clone=1
echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a /etc/sysctl.conf
```

#### 2. Missing lz4 Tool
```bash
# Error: lz4c command not found
sudo apt-get install lz4
```

#### 3. Insufficient Disk Space
```bash
# Clean build cache
bitbake -c cleanall
rm -rf build/sstate-cache/*
rm -rf build/tmp/*
```

#### 4. Network Issues
```bash
# Set proxy (if needed)
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
```

### Debug Tips

#### View Build Logs
```bash
# View failed task logs
find build/tmp/work -name "log.do_*" | grep error
```

#### Enter Development Shell
```bash
# Enter recipe development environment
bitbake -c devshell bootgen
```

#### Check Package Contents
```bash
# View generated package files
find build/tmp/work -name "*.ipk" | grep bootgen
```

## 📚 References

- [Yocto Project Official Documentation](https://docs.yoctoproject.org/)
- [Raspberry Pi Yocto BSP](https://github.com/agherzan/meta-raspberrypi)
- [Xilinx Bootgen User Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2019_2/ug1283-bootgen-user-guide.pdf)
- [BitBake User Manual](https://docs.yoctoproject.org/bitbake/)
