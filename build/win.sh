#!/usr/bin/env bash
set -e

# Dependency version numbers
source /packaging/versions.properties

VERSION_VIPS_SHORT=${VERSION_VIPS%.[[:digit:]]*}

# Common options for curl
CURL="curl --silent --location --retry 3 --retry-max-time 30"

# Fetch and unzip
mkdir /vips
cd /vips

case ${PLATFORM} in
  *arm64v8)
    ARCH=arm64
    ;;
  *x64)
    ARCH=w64
    ;;
  *ia32)
    ARCH=w32
    ;;
esac

FILENAME="vips-dev-${ARCH}-tropy-${VERSION_VIPS}.zip"
URL="https://github.com/tropy/build-win64-mxe/releases/download/v${VERSION_VIPS}/${FILENAME}"
echo "Downloading $URL"
$CURL -O $URL
unzip $FILENAME

# Clean and zip
cd /vips/vips-dev-${VERSION_VIPS_SHORT}
rm bin/libvips-cpp-42.dll
cp bin/*.dll lib/

# Add third-party notices
$CURL -O https://raw.githubusercontent.com/tropy/sharp-libvips/main/THIRD-PARTY-NOTICES.json

echo "Creating tarball"
tar czf /packaging/sharp-libvips-${PLATFORM}.tar.gz \
  include \
  lib/glib-2.0 \
  lib/libvips.lib \
  lib/libglib-2.0.lib \
  lib/libgobject-2.0.lib \
  lib/*.dll \
  *.json

# Allow tarballs to be read outside container
chmod 644 /packaging/sharp-libvips-${PLATFORM}.tar.*

# Remove working directories
rm -rf lib include *.json
