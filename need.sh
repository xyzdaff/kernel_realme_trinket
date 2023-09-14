#!/usr/bin/env bash
#
# Clang
echo 'Clone Clang'
   sudo apt-get update -y
   sudo apt-get install -y zstd
   mkdir -p "$HOME/toolchains/neutron-clang"
   cd "$HOME/toolchains/neutron-clang"
   bash <(curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman") -S
   cd "$HOME"

# Patch
echo 'Build libarchive for bsdtar'
    git clone https://github.com/libarchive/libarchive || true
    cd libarchive
    bash build/autogen.sh
    ./configure
    make -j$(nproc)
    cd ..
echo 'Patch for glibc'
	wget https://gist.githubusercontent.com/itsHanibee/fac63ea2fc0eca7b8d7dcbb7eb678c3b/raw/beacf8f0f71f4e8231eaa36c3e03d2bee9ae3758/patch-for-old-glibc.sh
	bash patch-for-old-glibc.sh