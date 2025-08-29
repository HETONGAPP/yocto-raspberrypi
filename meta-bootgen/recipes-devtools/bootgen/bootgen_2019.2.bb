DESCRIPTION = "Xilinx Bootgen tool for generating boot images"
HOMEPAGE = "https://www.xilinx.com/support/documentation/sw_manuals/xilinx2019_2/ug1283-bootgen-user-guide.pdf"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Use local source file
SRC_URI = "file://bootgen-2019.2.tar.gz"

S = "${WORKDIR}/bootgen-2019.2"

# Remove native inheritance to enable cross-compilation
# inherit native

# Dependencies for target build
DEPENDS = "openssl"

# Package configuration
PACKAGES = "${PN} ${PN}-dbg"
FILES_${PN} = "${bindir}/bootgen"
FILES_${PN}-dbg = "${bindir}/.debug/bootgen"

do_compile() {
    # Use Makefile's cross-compilation support
    make CROSS_COMPILER="${CXX}" \
         CXXFLAGS="${CXXFLAGS}" \
         LDFLAGS="${LDFLAGS}" \
         LIBS="-lssl -lcrypto" \
         INCLUDE_USER="-I${STAGING_INCDIR}"
}

do_install() {
    install -d ${D}${bindir}
    # Install the real compiled binary
    install -m 755 bootgen ${D}${bindir}/
}
