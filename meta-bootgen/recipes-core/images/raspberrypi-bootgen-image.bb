DESCRIPTION = "Raspberry Pi image with Xilinx Bootgen tool"
LICENSE = "MIT"

# Specify compatible machines (optional)
COMPATIBLE_MACHINE = "qemuarm64|raspberrypi4-64|raspberrypi4"

# Inherit from core-image for better base functionality
inherit core-image

# Include bootgen tool and basic packages
IMAGE_INSTALL += "bootgen"

# Add basic features for usability
IMAGE_FEATURES += "debug-tweaks ssh-server-openssh"

# Set image size to accommodate additional tools
IMAGE_ROOTFS_SIZE = "1048576"
