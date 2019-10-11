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

# Linux (x64)
if [ $PLATFORM = "all" ] || [ $PLATFORM = "linux-x64" ]; then
  echo "Building linux-x64..."
  sudo docker build -t vips-dev-linux-x64 linux-x64
  sudo docker run --rm -e "VERSION_VIPS=${VERSION_VIPS}" -v $PWD:/packaging vips-dev-linux-x64 sh -c "/packaging/build/lin.sh"
fi

# Display checksums
sha256sum *.tar.gz
