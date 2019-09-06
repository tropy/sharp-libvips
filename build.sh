#!/bin/sh
set -e

if [ $# -lt 1 ]; then
  echo
  echo "Usage: $0 VERSION [PLATFORM]"
  echo "Build shared libraries for libvips and its dependencies via containers"
  echo
  echo "Please specify the libvips VERSION, e.g. 8.7.0"
  echo
  echo "Optionally build for only one PLATFORM, defaults to building for all"
  echo
  echo "Possible values for PLATFORM are:"
  echo "- win32-x64"
  echo "- linux-x64"
  echo "- linuxmusl-x64"
  echo "- linux-armv6"
  echo "- linux-armv7"
  echo "- linux-arm64v8"
  echo
  exit 1
fi
VERSION_VIPS="$1"
PLATFORM="${2:-all}"

# Is docker available?
if ! type docker >/dev/null; then
  echo "Please install docker"
  exit 1
fi

# Update base images
for baseimage in centos:7 debian:stretch alpine:3.10; do
  sudo docker pull $baseimage
done

# Windows (x64)
if [ $PLATFORM = "all" ] || [ $PLATFORM = "win32-x64" ]; then
  echo "Building win32-x64..."
  sudo docker build -t vips-dev-win32-x64 win32-x64
  sudo docker run --rm -e "VERSION_VIPS=${VERSION_VIPS}" -v $PWD:/packaging vips-dev-win32-x64 sh -c "/packaging/build/win.sh"
fi

# Linux (x64, ARMv6, ARMv7, ARM64v8)
for flavour in linux-x64 linuxmusl-x64 linux-armv6 linux-armv7 linux-arm64v8; do
  if [ $PLATFORM = "all" ] || [ $PLATFORM = $flavour ]; then
    echo "Building $flavour..."
    sudo docker build -t vips-dev-$flavour $flavour
    sudo docker run --rm -e "VERSION_VIPS=${VERSION_VIPS}" -v $PWD:/packaging vips-dev-$flavour sh -c "/packaging/build/lin.sh"
  fi
done

# Display checksums
sha256sum *.tar.gz
