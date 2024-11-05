#!/bin/bash -e
# ----------------------------------------------------------------------------- 
# Package          : cryptography
# Versions         : 40.0.0 - 43.0.3
# Source repo      : https://github.com/pyca/cryptography.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rakshith B R <rakshith.r5@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on the given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=cryptography
PACKAGE_VERSION=${1:-42.0.7}  # Default to 42.0.7 if no version is specified
PACKAGE_URL=https://github.com/pyca/cryptography.git

# Validate if the version is supported (40.0.0 to 43.0.3)
if [[ ! "$PACKAGE_VERSION" =~ ^(40\.(0\.[0-9]|[1-2][0-9]|3)|41\.[0-9]+\.[0-9]+|42\.[0-9]+\.[0-9]+|43\.[0-3]\.[0-9]+)$ ]]; then
    echo "Unsupported version: $PACKAGE_VERSION."
    exit 1
fi

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip openssl

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed."
fi

# Install additional Python dependencies
pip install -r ci-constraints-requirements.txt
pip install .
pip install build wheel cython nox

# Build and install the package
if ! pyproject-build ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "$PACKAGE_NAME version $PACKAGE_VERSION has been successfully built and installed."
