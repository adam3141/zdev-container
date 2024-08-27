#!/bin/bash
set -e

echo "Installing Zephyr SDK feature."
echo "Zephyr SDK version: ${SDK_VERSION}"

# Set environment variables
ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-${SDK_VERSION}
ZEPHYR_SDK_DOWNLOAD_URL_BASE=https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}
ZEPHYR_SDK_HOST_TOOLS_FILENAME=hosttools_linux-x86_64.tar.xz
ZEPHYR_SDK_MINIMAL_FILENAME=zephyr-sdk-${SDK_VERSION}_linux-x86_64_minimal.tar.xz

# Create directory for SDK and toolchain setup
mkdir -p ${ZEPHYR_SDK_INSTALL_DIR}
cd ${ZEPHYR_SDK_INSTALL_DIR}

# Download and extract the SDK
echo "Receiving file ${ZEPHYR_SDK_MINIMAL_FILENAME}"
wget -q ${ZEPHYR_SDK_DOWNLOAD_URL_BASE}/${ZEPHYR_SDK_MINIMAL_FILENAME}
tar --strip-components=1 -xf ${ZEPHYR_SDK_INSTALL_DIR}/${ZEPHYR_SDK_MINIMAL_FILENAME}
# Remove the downloaded tarball
rm ${ZEPHYR_SDK_MINIMAL_FILENAME}



# Install the individual SDK toolchains
# Parse the TOOLCHAINS environment variable
IFS=',' read -ra TOOLCHAINS_ARRAY <<< "$TOOLCHAINS"

# Iterate over the toolchains and call the shell script to download & extract them
for toolchain in "${TOOLCHAINS_ARRAY[@]}"; do
    echo Installing toolchain ${toolchain}
    ./setup.sh -t ${toolchain} > /dev/null 2>&1
done

# Check if HOST_TOOLS is set to true and then call the setup script again to install them
if [ "$HOST_TOOLS" == "true" ]; then
    echo "Receiving file ${ZEPHYR_SDK_HOST_TOOLS_FILENAME}"
    wget -q ${ZEPHYR_SDK_DOWNLOAD_URL_BASE}/${ZEPHYR_SDK_HOST_TOOLS_FILENAME}
    tar --strip-components=1 -xf ${ZEPHYR_SDK_INSTALL_DIR}/${ZEPHYR_SDK_HOST_TOOLS_FILENAME}
    echo "Installing host tools"
    ./setup.sh -h

    # Remove the downloaded tarball
    rm ${ZEPHYR_SDK_HOST_TOOLS_FILENAME}
fi

# Register the Zephyr CMake package in remote user context. This requires that a feature or base image contains cmake
su - ${_REMOTE_USER} -c "${ZEPHYR_SDK_INSTALL_DIR}/setup.sh -c"
