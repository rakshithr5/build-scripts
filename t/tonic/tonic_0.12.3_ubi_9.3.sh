#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#
# Package	: tonic
# Version	: v0.12.3
# Source repo	: https://github.com/hyperium/tonic
# Tested on	: UBI 9.3
# Language      : Rust
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
SCRIPT_PACKAGE_VERSION=v0.12.3
PACKAGE_NAME=tonic
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/hyperium/tonic.git
BUILD_HOME=$(pwd)
PROTOC_VERSION=21.7

# Install update and deps
yum update -y
echo "Installing prerequisites..."
yum install -y git gcc gcc-c++ make clang openssl-devel zlib-devel wget

echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo "Configuring the shell..."
source "$HOME/.cargo/env"

# rustc --print=target-list
rustup target add powerpc64le-unknown-linux-gnu
# rustup target add powerpc64-unknown-freebsd

cargo install cargo-hack

# Check if Rust is installed successfully
if command -v rustc &>/dev/null; then
    echo "Rust installed successfully!"
    rustc --version
else
    echo "Rust installation failed."
fi

# set env variable
set RUST_BACKTRACE=full

# Change to home directory
cd $BUILD_HOME

# downloading the protoc archive, extract the contents  
echo "Download protoc archive"
wget https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOC_VERSION/protobuf-all-$PROTOC_VERSION.tar.gz
echo "Extract protoc archive"
tar -zvxf protobuf-all-$PROTOC_VERSION.tar.gz --no-same-owner
cd protobuf-$PROTOC_VERSION

# Set up the build environment
echo "Set up the build environment"
./configure

# Compile the source code
echo "Compile protoc"
make

# Install the compiled protoc
echo "Install protoc"
make install

# Check if protoc is installed successfully
if command -v protoc &>/dev/null; then
    echo "protoc installed successfully!"
    rustc --version
else
    echo "protoc installation failed."
fi

cd ..

# Build and install tonic
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Run Build
echo "Rust build!"
if ! cargo build --release; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_Fails"
    exit 1
fi

# Run install check
echo "Run install check and Test"
if ! cargo test --workspace --all-features; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    export Tonic_Build='/home/tonic/target/release/libtonic.d'
    echo "Tonic Build completed."
    echo "Tonic bit binary is available at [$Tonic_Build]."
    exit 0
fi