#!/usr/bin/env bash
set -e

# Environment / working directories
case ${PLATFORM} in
  linux*)
    LINUX=true
    DEPS=/deps
    TARGET=/target
    PACKAGE=/packaging
    ROOT=/root
    VIPS_CPP_DEP=libvips-cpp.so.42
    ;;
  darwin*)
    DARWIN=true
    DEPS=$PWD/deps
    TARGET=$PWD/target
    PACKAGE=$PWD
    ROOT=$PWD/$PLATFORM
    VIPS_CPP_DEP=libvips-cpp.42.dylib
    ;;
esac

mkdir ${DEPS}
mkdir ${TARGET}

# Default optimisation level is for binary size (-Os)
# Overriden to performance (-O3) for select dependencies that benefit
export FLAGS+=" -Os -fPIC"

# Force "new" C++11 ABI compliance
# Remove async exception unwind/backtrace tables
# Allow linker to remove unused sections
if [ "$LINUX" = true ]; then
  export FLAGS+=" -D_GLIBCXX_USE_CXX11_ABI=1 -fno-asynchronous-unwind-tables -ffunction-sections -fdata-sections"
fi

# Common build paths and flags
export PATH="${PATH}:${TARGET}/bin"
export CPATH="${TARGET}/include"
export LIBRARY_PATH="${TARGET}/lib"
export LD_LIBRARY_PATH="${TARGET}/lib"
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"
export OBJCFLAGS="${FLAGS}"
export OBJCXXFLAGS="${FLAGS}"
export LDFLAGS="-L${TARGET}/lib"

if [ $TYPE = "shared" ]; then
  TYPE_SHARED=true
  TYPE_FLAGS="--enable-shared --disable-static"
  TYPE_FLAGS_CMAKE="-DBUILD_SHARED_LIBS=TRUE -DBUILD_STATIC_LIBS=FALSE"

  export PKG_CONFIG_PATH="${TARGET}/lib/pkgconfig:${PKG_CONFIG_PATH}"

  # Instead of using a deps group parameter: only Electron requires
  # the shared library build with old system libraries for now!
  ELECTRON=true
else
  TYPE="static"
  TYPE_STATIC=true
  TYPE_FLAGS="--disable-shared --enable-static"
  TYPE_FLAGS_CMAKE="-DBUILD_SHARED_LIBS=FALSE -DBUILD_STATIC_LIBS=TRUE"

  # We don't want to use any native libraries, so unset PKG_CONFIG_PATH
  export PKG_CONFIG_LIBDIR="${TARGET}/lib/pkgconfig"
  unset PKG_CONFIG_PATH
fi

# On Linux, we need to create a relocatable library
# Note: this is handled for macOS using the `install_name_tool` (see below)
if [ "$LINUX" = true ]; then
  export LDFLAGS+=" -Wl,--gc-sections -Wl,-rpath='\$\$ORIGIN/'"
fi

# On macOS, we need to explicitly link against the system libraries
if [ "$DARWIN" = true ]; then
  export LDFLAGS+=" -framework CoreServices -framework CoreFoundation -framework Foundation -framework AppKit"

  if [ "$PLATFORM" == "darwin-arm64v8" ]; then
    export DARWIN_ARM=true

    if [ "$(uname -m)" != "arm64" ]; then
      export PKG_CONFIG="$(brew --prefix)/bin/pkg-config"
    fi
  fi
fi

# Run as many parallel jobs as there are available CPU cores
if [ "$LINUX" = true ]; then
  export MAKEFLAGS="-j$(nproc)"
elif [ "$DARWIN" = true ]; then
  export MAKEFLAGS="-j$(sysctl -n hw.logicalcpu)"
fi

# Optimise Rust code for binary size
export CARGO_PROFILE_RELEASE_DEBUG=false
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
export CARGO_PROFILE_RELEASE_INCREMENTAL=false
export CARGO_PROFILE_RELEASE_LTO=true
export CARGO_PROFILE_RELEASE_OPT_LEVEL=z
export CARGO_PROFILE_RELEASE_PANIC=abort

# Workaround for https://github.com/rust-lang/compiler-builtins/issues/353
# (applies only to ARMv6 and ARMv7)
if [[ $PLATFORM == "linux-armv"* ]]; then
  export LDFLAGS+=" -Wl,--allow-multiple-definition"
fi

# Common options for curl
CURL="curl --silent --location --retry 3 --retry-max-time 30"

# Dependency version numbers
VERSION_ZLIB_NG=2.0.5
VERSION_FFI=3.4.2
VERSION_GLIB=2.69.0
VERSION_XML2=2.9.12
VERSION_GSF=1.14.47
VERSION_EXIF=0.6.22
VERSION_LCMS2=2.12
VERSION_MOZJPEG=4.0.3
VERSION_PNG16=1.6.37
VERSION_SPNG=0.6.3
VERSION_IMAGEQUANT=2.4.1
VERSION_WEBP=1.2.0
VERSION_TIFF=4.3.0
VERSION_ORC=0.4.32
VERSION_PROXY_LIBINTL=ef9fe6d
VERSION_GDKPIXBUF=2.42.6
VERSION_FREETYPE=2.10.4
VERSION_EXPAT=2.4.1
VERSION_FONTCONFIG=2.13.93
VERSION_HARFBUZZ=2.8.1
VERSION_PIXMAN=0.40.0
VERSION_CAIRO=1.17.4
VERSION_FRIBIDI=1.0.10
VERSION_PANGO=1.48.7
VERSION_SVG=2.51.3
VERSION_AOM=3.1.1
VERSION_HEIF=1.12.0

# Extra dependencies for Tropy
VERSION_MAGICK="7.0.11-6"
VERSION_DE265=1.0.8
VERSION_OPENJPEG=2.4.0
VERSION_POPPLER=21.04.0
VERSION_JPEG=2.0.6

# Remove patch version component
without_patch() {
  echo "${1%.[[:digit:]]*}"
}

# Check for newer versions
# Skip by setting the VERSION_LATEST_REQUIRED environment variable to "false"
ALL_AT_VERSION_LATEST=true
version_latest() {
  if [ "$VERSION_LATEST_REQUIRED" == "false" ]; then
    echo "Skipping latest version check for $1"
    return
  fi
  VERSION_LATEST=$($CURL "https://release-monitoring.org/api/v2/versions/?project_id=$3" | jq -j ".stable_versions[0]")
  if [ "$VERSION_LATEST" != "$2" ]; then
    ALL_AT_VERSION_LATEST=false
    echo "$1 version $2 has been superseded by $VERSION_LATEST"
  fi
}
version_latest "zlib-ng" "$VERSION_ZLIB_NG" "115592"
version_latest "ffi" "$VERSION_FFI" "1611"
#version_latest "glib" "$VERSION_GLIB" "10024" # latest version in release monitoring is development version
version_latest "xml2" "$VERSION_XML2" "1783"
version_latest "gsf" "$VERSION_GSF" "1980"
version_latest "exif" "$VERSION_EXIF" "1607"
version_latest "lcms2" "$VERSION_LCMS2" "9815"
version_latest "png" "$VERSION_PNG16" "1705"
version_latest "spng" "$VERSION_SPNG" "24289"
version_latest "webp" "$VERSION_WEBP" "1761"
version_latest "tiff" "$VERSION_TIFF" "1738"
version_latest "orc" "$VERSION_ORC" "2573"
version_latest "gdkpixbuf" "$VERSION_GDKPIXBUF" "9533"
version_latest "freetype" "$VERSION_FREETYPE" "854"
version_latest "expat" "$VERSION_EXPAT" "770"
#version_latest "fontconfig" "$VERSION_FONTCONFIG" "827" # 2.13.94 fails to build on macOS
version_latest "harfbuzz" "$VERSION_HARFBUZZ" "1299"
version_latest "pixman" "$VERSION_PIXMAN" "3648"
version_latest "cairo" "$VERSION_CAIRO" "247"
version_latest "fribidi" "$VERSION_FRIBIDI" "857"
version_latest "pango" "$VERSION_PANGO" "11783"
version_latest "svg" "$VERSION_SVG" "5420"
version_latest "aom" "$VERSION_AOM" "17628"
version_latest "de265" "$VERSION_DE265" "11239"
version_latest "heif" "$VERSION_HEIF" "64439"
version_latest "openjpeg" "$VERSION_OPENJPEG" "2550"
version_latest "poppler" "$VERSION_POPPLER" "3686"
version_latest "imagemagick" "$VERSION_MAGICK" "1372" # "16253"
version_latest "jpeg" "$VERSION_JPEG" "1648"
if [ "$ALL_AT_VERSION_LATEST" = "false" ]; then exit 1; fi

# Download and build dependencies from source

if [ "${PLATFORM%-*}" == "linuxmusl" ] || [ "$DARWIN" = true ]; then
  mkdir ${DEPS}/proxy-libintl
  $CURL https://github.com/frida/proxy-libintl/archive/${VERSION_PROXY_LIBINTL}.tar.gz | tar xzC ${DEPS}/proxy-libintl --strip-components=1
  cd ${DEPS}/proxy-libintl
  LDFLAGS=${LDFLAGS/\$/} meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON}
  ninja -C _build
  ninja -C _build install
fi

if [ ! "$ELECTRON" = true ]; then
  mkdir ${DEPS}/zlib-ng
  $CURL https://github.com/zlib-ng/zlib-ng/archive/${VERSION_ZLIB_NG}.tar.gz | tar xzC ${DEPS}/zlib-ng --strip-components=1
  cd ${DEPS}/zlib-ng
  CFLAGS="${CFLAGS} -O3" LDFLAGS=${LDFLAGS/\$/} cmake -G"Unix Makefiles" \
    ${TYPE_FLAGS_CMAKE} -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DBUILD_SHARED_LIBS=FALSE -DZLIB_COMPAT=TRUE
  make install/strip

  mkdir ${DEPS}/ffi
  $CURL https://github.com/libffi/libffi/releases/download/v${VERSION_FFI}/libffi-${VERSION_FFI}.tar.gz | tar xzC ${DEPS}/ffi --strip-components=1
  cd ${DEPS}/ffi
  if [ "$DARWIN_ARM" = true ]; then
    # See https://github.com/libffi/libffi/pull/565
    $CURL https://raw.githubusercontent.com/Homebrew/formula-patches/a4a91e61/libffi/libffi-3.3-arm64.patch | patch -p1
  fi
  ./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
    --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-structs
  make install-strip

  mkdir ${DEPS}/glib
  $CURL https://download.gnome.org/sources/glib/$(without_patch $VERSION_GLIB)/glib-${VERSION_GLIB}.tar.xz | tar xJC ${DEPS}/glib --strip-components=1
  cd ${DEPS}/glib
  if [ "${PLATFORM%-*}" == "linuxmusl" ]; [ "$DARWIN" = true ]; then
    $CURL https://gist.github.com/kleisauke/f6dcbf02a9aa43fd582272c3d815e7a8/raw/13049037ce45592d0eb76a12a761212bc48bc879/glib-proxy-libintl.patch | patch -p1
  fi
  $CURL https://gist.githubusercontent.com/lovell/7e0ce65249b951d5be400fb275de3924/raw/1a833ef4263271d299587524198b024eb5cc4f34/glib-without-gregex.patch | patch -p1
  LDFLAGS=${LDFLAGS/\$/} meson setup _build --default-library=${TYPE} --buildtype=release --strip --prefix=${TARGET} ${MESON} \
    --force-fallback-for=libpcre -Dtests=false -Dinstalled_tests=false -Dlibmount=disabled -Dlibelf=disabled ${DARWIN:+-Dbsymbolic_functions=false}
  ninja -C _build
  ninja -C _build install
fi

mkdir ${DEPS}/xml2
$CURL http://xmlsoft.org/sources/libxml2-${VERSION_XML2}.tar.gz | tar xzC ${DEPS}/xml2 --strip-components=1
cd ${DEPS}/xml2
# Remove --with-regexps flag from v2.10.0+
./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
  --with-minimum --with-reader --with-writer --with-valid --with-http --with-tree \
  --without-python --without-lzma ${INCLUDE_ZLIB:+--with-zlib=${TARGET}}
make install-strip

mkdir ${DEPS}/gsf
$CURL https://download.gnome.org/sources/libgsf/$(without_patch $VERSION_GSF)/libgsf-${VERSION_GSF}.tar.xz | tar xJC ${DEPS}/gsf --strip-components=1
cd ${DEPS}/gsf
# Skip unused subdirs
sed -i'.bak' "s/ doc tools tests thumbnailer python//" Makefile.in
./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
  --without-bz2 --without-gdk-pixbuf --disable-nls --without-libiconv-prefix --without-libintl-prefix ${INCLUDE_ZLIB:+--with-zlib=${TARGET}}
make install-strip

mkdir ${DEPS}/exif
$CURL https://github.com/libexif/libexif/releases/download/libexif-${VERSION_EXIF//./_}-release/libexif-${VERSION_EXIF}.tar.xz | tar xJC ${DEPS}/exif --strip-components=1
cd ${DEPS}/exif
autoreconf -fiv
./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
  --disable-nls --without-libiconv-prefix --without-libintl-prefix \
  CPPFLAGS="-DNO_VERBOSE_TAG_DATA"
make install-strip

mkdir ${DEPS}/lcms2
$CURL https://downloads.sourceforge.net/project/lcms/lcms/${VERSION_LCMS2}/lcms2-${VERSION_LCMS2}.tar.gz | tar xzC ${DEPS}/lcms2 --strip-components=1
cd ${DEPS}/lcms2
CFLAGS="${CFLAGS} -O3" ./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/aom
$CURL https://storage.googleapis.com/aom-releases/libaom-${VERSION_AOM}.tar.gz | tar xzC ${DEPS}/aom
cd ${DEPS}/aom
mkdir aom_build
cd aom_build
AOM_AS_FLAGS="${FLAGS}" LDFLAGS=${LDFLAGS/\$/} cmake -G"Unix Makefiles" ${TYPE_SHARED:+-DENABLE_SHARED_LIBS=1} \
  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DENABLE_DOCS=0 -DENABLE_TESTS=0 -DENABLE_TESTDATA=0 -DENABLE_TOOLS=0 -DENABLE_EXAMPLES=0 \
  -DCONFIG_PIC=1 -DENABLE_NASM=1 ${WITHOUT_NEON:+-DENABLE_NEON=0} ${DARWIN_ARM:+-DCONFIG_RUNTIME_CPU_DETECT=0} \
  -DCONFIG_AV1_HIGHBITDEPTH=0 -DCONFIG_WEBM_IO=0 \
  ..
make install/strip

mkdir ${DEPS}/de265
$CURL https://github.com/strukturag/libde265/releases/download/v${VERSION_DE265}/libde265-${VERSION_DE265}.tar.gz | tar xzC ${DEPS}/de265 --strip-components=1
cd ${DEPS}/de265
./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
  --disable-dec265 --disable-sherlock265 ${DARWIN_ARM:+--disable-arm}
make install-strip

mkdir ${DEPS}/heif
$CURL https://github.com/strukturag/libheif/releases/download/v${VERSION_HEIF}/libheif-${VERSION_HEIF}.tar.gz | tar xzC ${DEPS}/heif --strip-components=1
cd ${DEPS}/heif
# [PATCH] aom encoder: improve performance by ~2x using new 'all intra'
$CURL https://github.com/lovell/libheif/commit/de0c159a60c2c50931321f06e36a3b6640c5c807.patch | patch -p1
# [PATCH] aom: expose decoder error messages
$CURL https://github.com/lovell/libheif/commit/7e1c1888023f6dd68cf33e537e7eb8e4d5e17588.patch | patch -p1
# [PATCH] Detect and prevent negative overflow of clap box dimensions
$CURL https://github.com/lovell/libheif/commit/e625a702ec7d46ce042922547d76045294af71d6.patch | git apply -
CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" ./configure \
  --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
  --disable-gdk-pixbuf --disable-go --disable-examples --disable-x265
make install-strip

mkdir ${DEPS}/jpeg
$CURL https://github.com/mozilla/mozjpeg/archive/v${VERSION_MOZJPEG}.tar.gz | tar xzC ${DEPS}/jpeg --strip-components=1
#$CURL https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${VERSION_JPEG}.tar.gz | tar xzC ${DEPS}/jpeg --strip-components=1
cd ${DEPS}/jpeg
LDFLAGS=${LDFLAGS/\$/} cmake -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=${TARGET}/lib \
  ${TYPE_SHARED:+-DENABLE_STATIC=0} ${TYPE_STATIC:+-DENABLE_SHARED=0} -DWITH_JPEG8=1 -DWITH_TURBOJPEG=FALSE -DPNG_SUPPORTED=FALSE
make install/strip

mkdir ${DEPS}/png16
$CURL https://downloads.sourceforge.net/project/libpng/libpng16/${VERSION_PNG16}/libpng-${VERSION_PNG16}.tar.xz | tar xJC ${DEPS}/png16 --strip-components=1
cd ${DEPS}/png16
CFLAGS="${CFLAGS} -O3" ./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/spng
$CURL https://github.com/randy408/libspng/archive/v${VERSION_SPNG}.tar.gz | tar xzC ${DEPS}/spng --strip-components=1
cd ${DEPS}/spng
CFLAGS="${CFLAGS} -O3" meson setup _build --default-library=${TYPE} --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  ${TYPE_STATIC+-Dstatic_zlib=true}
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/imagequant
$CURL https://github.com/lovell/libimagequant/archive/v${VERSION_IMAGEQUANT}.tar.gz | tar xzC ${DEPS}/imagequant --strip-components=1
cd ${DEPS}/imagequant
CFLAGS="${CFLAGS} -O3" meson setup _build --default-library=${TYPE} --buildtype=release --strip --prefix=${TARGET} ${MESON}
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/webp
$CURL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${VERSION_WEBP}.tar.gz | tar xzC ${DEPS}/webp --strip-components=1
cd ${DEPS}/webp
./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
  --disable-neon --enable-libwebpmux --enable-libwebpdemux
make install-strip

mkdir ${DEPS}/tiff
$CURL https://download.osgeo.org/libtiff/tiff-${VERSION_TIFF}.tar.gz | tar xzC ${DEPS}/tiff --strip-components=1
cd ${DEPS}/tiff
if [ -n "${CHOST}" ]; then autoreconf -fiv; fi
./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
  --disable-mdi --disable-pixarlog --disable-old-jpeg --disable-cxx --disable-lzma --disable-zstd \
  --with-jpeg-include-dir=${TARGET}/include --with-jpeg-lib-dir=${TARGET}/lib
make install-strip

mkdir ${DEPS}/orc
$CURL https://gstreamer.freedesktop.org/data/src/orc/orc-${VERSION_ORC}.tar.xz | tar xJC ${DEPS}/orc --strip-components=1
cd ${DEPS}/orc
LDFLAGS=${LDFLAGS/\$/} meson setup _build --default-library=${TYPE} --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dorc-test=disabled -Dbenchmarks=disabled -Dexamples=disabled -Dgtk_doc=disabled -Dtests=disabled -Dtools=disabled
ninja -C _build
ninja -C _build install

if [ ! "$ELECTRON" = true ]; then
  mkdir ${DEPS}/gdkpixbuf
  $CURL https://download.gnome.org/sources/gdk-pixbuf/$(without_patch $VERSION_GDKPIXBUF)/gdk-pixbuf-${VERSION_GDKPIXBUF}.tar.xz | tar xJC ${DEPS}/gdkpixbuf --strip-components=1
  cd ${DEPS}/gdkpixbuf
  # Disable tests and thumbnailer
  sed -i'.bak' "/subdir('tests')/{N;d;}" meson.build
  sed -i'.bak' "/post-install/{N;N;N;N;d;}" meson.build
  # Disable the built-in loaders for BMP, GIF, ICO, PNM, XPM, XBM, TGA, ICNS and QTIF
  sed -i'.bak' "/'bmp':/{N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;d;}" gdk-pixbuf/meson.build
  sed -i'.bak' "/'pnm':/{N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;d;}" gdk-pixbuf/meson.build
  # Skip executables
  sed -i'.bak' "/gdk-pixbuf-csource/{N;N;d;}" gdk-pixbuf/meson.build
  sed -i'.bak' "/loaders_cache = custom/{N;N;N;N;N;N;N;N;N;c\\
    loaders_cache = []\\
    loaders_dep = declare_dependency()
  }" gdk-pixbuf/meson.build
  sed -i'.bak' "/gdk-pixbuf-query-loaders/d" build-aux/post-install.sh
  # Ensure meson can find libjpeg when cross-compiling
  sed -i'.bak' "s/has_header('jpeglib.h')/has_header('jpeglib.h', args: '-I\/target\/include')/g" meson.build
  sed -i'.bak' "s/cc.find_library('jpeg'/dependency('libjpeg'/g" meson.build
  LDFLAGS=${LDFLAGS/\$/} meson setup _build --default-library=${TYPE} --buildtype=release --strip --prefix=${TARGET} ${MESON} \
    -Dtiff=false -Dintrospection=disabled -Dinstalled_tests=false -Dgio_sniffing=false -Dman=false -Dbuiltin_loaders=png,jpeg
  ninja -C _build
  ninja -C _build install
  # Include libjpeg and libpng as a dependency of gdk-pixbuf, see: https://gitlab.gnome.org/GNOME/gdk-pixbuf/merge_requests/50
  sed -i'.bak' "s/^\(Requires:.*\)/\1 libjpeg, libpng16/" ${TARGET}/lib/pkgconfig/gdk-pixbuf-2.0.pc

  mkdir ${DEPS}/freetype
  $CURL https://download.savannah.gnu.org/releases/freetype/freetype-${VERSION_FREETYPE}.tar.xz | tar xJC ${DEPS}/freetype --strip-components=1
  cd ${DEPS}/freetype
  ./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
    --without-bzip2 --without-png
  make install

  mkdir ${DEPS}/expat
  $CURL https://github.com/libexpat/libexpat/releases/download/R_${VERSION_EXPAT//./_}/expat-${VERSION_EXPAT}.tar.xz | tar xJC ${DEPS}/expat --strip-components=1
  cd ${DEPS}/expat
  ./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} \
  --disable-dependency-tracking --without-xmlwf --without-docbook --without-getrandom --without-sys-getrandom \
  --without-libbsd --without-examples --without-tests
  make install

  mkdir ${DEPS}/fontconfig
  $CURL https://www.freedesktop.org/software/fontconfig/release/fontconfig-${VERSION_FONTCONFIG}.tar.xz | tar xJC ${DEPS}/fontconfig --strip-components=1
  cd ${DEPS}/fontconfig
  ./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
    --with-expat-includes=${TARGET}/include --with-expat-lib=${TARGET}/lib ${LINUX:+--sysconfdir=/etc} \
    ${DARWIN:+--sysconfdir=$(brew --prefix)/etc} --disable-docs --disable-nls
  make install-strip

  mkdir ${DEPS}/harfbuzz
  $CURL https://github.com/harfbuzz/harfbuzz/archive/${VERSION_HARFBUZZ}.tar.gz | tar xzC ${DEPS}/harfbuzz --strip-components=1
  cd ${DEPS}/harfbuzz
  # Disable utils
  sed -i'.bak' "/subdir('util')/d" meson.build
  LDFLAGS=${LDFLAGS/\$/} meson setup _build --default-library=${TYPE} --buildtype=release --strip --prefix=${TARGET} ${MESON} \
    -Dgobject=disabled -Dicu=disabled -Dtests=disabled -Dintrospection=disabled -Ddocs=disabled -Dbenchmark=disabled ${DARWIN:+-Dcoretext=enabled}
  ninja -C _build
  ninja -C _build install

  mkdir ${DEPS}/pixman
  $CURL https://cairographics.org/releases/pixman-${VERSION_PIXMAN}.tar.gz | tar xzC ${DEPS}/pixman --strip-components=1
  cd ${DEPS}/pixman
  # Disable tests and demos
  sed -i'.bak' "/subdir('test')/{N;d;}" meson.build
  LDFLAGS=${LDFLAGS/\$/} meson setup _build --default-library=${TYPE} --buildtype=release --strip --prefix=${TARGET} ${MESON} \
    -Dlibpng=disabled -Diwmmxt=disabled -Dgtk=disabled -Dopenmp=disabled
  ninja -C _build
  ninja -C _build install

  mkdir ${DEPS}/cairo
  $CURL https://cairographics.org/snapshots/cairo-${VERSION_CAIRO}.tar.xz | tar xJC ${DEPS}/cairo --strip-components=1
  cd ${DEPS}/cairo
  sed -i'.bak' "s/^\(Libs:.*\)/\1 @CAIRO_NONPKGCONFIG_LIBS@/" src/cairo.pc.in
  CFLAGS="$CFLAGS ${LINUX:+-fno-function-sections -fno-data-sections}" LDFLAGS="$LDFLAGS ${LINUX:+-Wl,--no-gc-sections}" ./configure \
    --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
    --disable-xlib --disable-xcb --disable-win32 --disable-egl --disable-glx --disable-wgl --disable-ps \
    --disable-trace --disable-interpreter ${LINUX:+--disable-quartz} ${DARWIN:+--enable-quartz-image} \
    LIBS="-lpixman-1 -lfreetype"
  make install-strip

  mkdir ${DEPS}/fribidi
  $CURL https://github.com/fribidi/fribidi/releases/download/v${VERSION_FRIBIDI}/fribidi-${VERSION_FRIBIDI}.tar.xz | tar xJC ${DEPS}/fribidi --strip-components=1
  cd ${DEPS}/fribidi
  # Disable tests
  sed -i'.bak' "/subdir('test')/d" meson.build
  LDFLAGS=${LDFLAGS/\$/} meson setup _build --default-library=${TYPE} --buildtype=release --strip --prefix=${TARGET} ${MESON} \
    -Ddocs=false
  ninja -C _build
  ninja -C _build install

  mkdir ${DEPS}/pango
  $CURL https://download.gnome.org/sources/pango/$(without_patch $VERSION_PANGO)/pango-${VERSION_PANGO}.tar.xz | tar xJC ${DEPS}/pango --strip-components=1
  cd ${DEPS}/pango
  # Disable utils, examples, tests and tools
  sed -i'.bak' "/subdir('utils')/{N;N;N;d;}" meson.build
  LDFLAGS=${LDFLAGS/\$/} meson setup _build --default-library=${TYPE} --buildtype=release --strip --prefix=${TARGET} ${MESON} \
    -Dgtk_doc=false -Dintrospection=disabled -Dfontconfig=enabled
  ninja -C _build
  ninja -C _build install

  mkdir ${DEPS}/svg
  $CURL https://download.gnome.org/sources/librsvg/$(without_patch $VERSION_SVG)/librsvg-${VERSION_SVG}.tar.xz | tar xJC ${DEPS}/svg --strip-components=1
  cd ${DEPS}/svg
  sed -i'.bak' "s/^\(Requires:.*\)/\1 cairo-gobject pangocairo/" librsvg.pc.in
  # LTO optimization does not work for staticlib+rlib compilation
  sed -i'.bak' "s/, \"rlib\"//" Cargo.toml
  # Skip executables
  sed -i'.bak' "/SCRIPTS = /d" Makefile.in
  ./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking \
    --disable-introspection --disable-tools --disable-pixbuf-loader --disable-nls --without-libiconv-prefix --without-libintl-prefix \
    ${DARWIN:+--disable-Bsymbolic}
  make install-strip
fi

mkdir ${DEPS}/gif
$CURL https://downloads.sourceforge.net/project/giflib/giflib-${VERSION_GIF}.tar.gz | tar xzC ${DEPS}/gif --strip-components=1
cd ${DEPS}/gif
CFLAGS="${CFLAGS} -O3" ./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} --disable-dependency-tracking
make install-strip

mkdir -p ${DEPS}/openjpeg/build
$CURL https://github.com/uclouvain/openjpeg/archive/v${VERSION_OPENJPEG}.tar.gz | tar xzC ${DEPS}/openjpeg --strip-components=1
cd ${DEPS}/openjpeg/build
LDFLAGS=${LDFLAGS/\$/} cmake .. -G"Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} \
  ${TYPE_FLAGS_CMAKE} -DBUILD_CODEC=OFF -DCMAKE_BUILD_TYPE=Release
make install/strip

mkdir -p ${DEPS}/poppler/build
$CURL https://poppler.freedesktop.org/poppler-${VERSION_POPPLER}.tar.xz | tar xJC ${DEPS}/poppler --strip-components=1
cd ${DEPS}/poppler/build
# Skip building and linking pfd-fullrewrite
sed -i'.bak' "/subdirectory(test)/d" ../CMakeLists.txt
# Add libopenjp2 to pkg-config linker flags
sed -i'.bak' "s/-lpoppler/& -lopenjp2/" ../poppler.pc.cmake
LDFLAGS=${LDFLAGS/\$/} cmake .. -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake \
  -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=${TARGET}/lib -DCMAKE_PREFIX_PATH=${TARGET} \
  ${TYPE_FLAGS_CMAKE} -DCMAKE_BUILD_TYPE=release \
  -DENABLE_ZLIB_UNCOMPRESS=OFF -DENABLE_LIBOPENJPEG=openjpeg2 -DENABLE_CMS=lcms2 -DENABLE_DCTDECODER=libjpeg \
  -DENABLE_SPLASH=OFF -DENABLE_UTILS=OFF \
  -DENABLE_QT5=OFF -DENABLE_QT6=OFF -DENABLE_CPP=OFF -DENABLE_LIBCURL=OFF -DENABLE_GOBJECT_INTROSPECTION=OFF \
  -DBUILD_GTK_TESTS=OFF -DBUILD_QT5_TESTS=OFF -DBUILD_QT6_TESTS=OFF -DBUILD_CPP_TESTS=OFF -DEXTRA_WARN=OFF
make install/strip

mkdir ${DEPS}/imagemagick
#$CURL https://download.imagemagick.org/ImageMagick/download/releases/ImageMagick-${VERSION_MAGICK}.tar.gz | tar xzC ${DEPS}/imagemagick --strip-components=1
$CURL https://github.com/ImageMagick/ImageMagick/archive/refs/tags/${VERSION_MAGICK}.tar.gz | tar xzC ${DEPS}/imagemagick --strip-components=1
cd ${DEPS}/imagemagick
./configure --host=${CHOST} --prefix=${TARGET} ${TYPE_FLAGS} \
  --enable-zero-configuration --without-modules --without-ltdl --disable-opencl \
  --disable-openmp --disable-dependency-tracking --disable-deprecated --disable-docs \
  --without-utilities --without-magick-plus-plus --without-perl \
  --with-openjp2 --with-jbig \
  --without-fftw --without-fontconfig --without-freetype --without-gvc \
  --without-gslib --without-heic --without-lqr --without-lzma --without-openexr \
  --without-pango --without-rsvg --without-webp --without-x --without-xml \
  --without-png --without-jpeg --without-tiff \
  --without-zip --without-zlib --without-zstd
make install-strip

mkdir ${DEPS}/vips
$CURL https://github.com/libvips/libvips/releases/download/v${VERSION_VIPS}/vips-${VERSION_VIPS}.tar.gz | tar xzC ${DEPS}/vips --strip-components=1
cd ${DEPS}/vips
# Prevent exporting the g_param_spec_types symbol to avoid collisions with shared libraries
printf "{\n\
local:\n\
    g_param_spec_types;\n\
};" > vips.map
PKG_CONFIG="pkg-config${TYPE_STATIC:+ --static}" CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" ./configure \
  --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --disable-debug --disable-deprecated --disable-introspection --without-analyze --without-cfitsio --without-fftw \
  --without-matio --without-nifti --without-OpenEXR --without-openslide \
  --without-pdfium --without-ppm --without-radiance --without-pangoft2 \
  --with-png-includes=${TARGET/include} --with-png-libraries=${TARGET}/lib
# https://docs.fedoraproject.org/en-US/packaging-guidelines/#_removing_rpath
sed -i'.bak' 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g' libtool
# Link libvips.so.42 statically into libvips-cpp.so.42
make -C 'libvips' install-strip LDFLAGS="-static $LDFLAGS"
make -C 'cplusplus' install-strip ${LINUX:+LDFLAGS="$LDFLAGS -Wl,-Bsymbolic-functions -Wl,--version-script=$DEPS/vips/vips.map"}

# Cleanup
rm -rf ${TARGET}/lib/{pkgconfig,.libs,*.la,cmake}

mkdir ${TARGET}/lib-filtered

if [ -d ${TARGET}/lib/glib-2.0 ]; then
  mv ${TARGET}/lib/glib-2.0 ${TARGET}/lib-filtered
else
  # Pack system glib includes if we didn't build it!
  cp -r /usr/lib64/glib-2.0 ${TARGET}/lib-filtered
  cp -r /usr/include/glib-2.0 ${TARGET}/include/
fi

# Pack only the relevant libraries
# Note: we can't use ldd on Linux, since that can only be executed on the target machine
# Note 2: we modify all dylib dependencies to use relative paths on macOS
function copydeps {
  local base=$1
  local dest_dir=$2

  cp -L $base $dest_dir/$base
  chmod 644 $dest_dir/$base

  if [ "$LINUX" = true ]; then
    local dependencies=$(readelf -d $base | grep NEEDED | awk '{ print $5 }' | tr -d '[]')
  elif [ "$DARWIN" = true ]; then
    local dependencies=$(otool -LX $base | awk '{print $1}' | grep $TARGET)

    install_name_tool -id @rpath/$base $dest_dir/$base
  fi

  for dep in $dependencies; do
    base_dep=$(basename $dep)

    [ ! -f "$PWD/$base_dep" ] && echo "$base_dep does not exist in $PWD" && continue
    echo "$base depends on $base_dep"

    if [ "$DARWIN" = true ]; then
      install_name_tool -change $dep @rpath/$base_dep $dest_dir/$base
    fi

    if [ ! -f "$dest_dir/$base_dep" ]; then
      # Call this function (recursive) on each dependency of this library
      copydeps $base_dep $dest_dir
    fi
  done;
}

cd ${TARGET}/lib
copydeps ${VIPS_CPP_DEP} ${TARGET}/lib-filtered

# Create JSON file of version numbers
cd ${TARGET}
printf "{\n\
  \"aom\": \"${VERSION_AOM}\",\n\
  \"cairo\": \"${VERSION_CAIRO}\",\n\
  \"exif\": \"${VERSION_EXIF}\",\n\
  \"expat\": \"${VERSION_EXPAT}\",\n\
  \"de265\": \"${VERSION_DE265}\",\n\
  \"ffi\": \"${VERSION_FFI}\",\n\
  \"fontconfig\": \"${VERSION_FONTCONFIG}\",\n\
  \"freetype\": \"${VERSION_FREETYPE}\",\n\
  \"fribidi\": \"${VERSION_FRIBIDI}\",\n\
  \"gdkpixbuf\": \"${VERSION_GDKPIXBUF}\",\n\
  \"glib\": \"${VERSION_GLIB}\",\n\
  \"gsf\": \"${VERSION_GSF}\",\n\
  \"harfbuzz\": \"${VERSION_HARFBUZZ}\",\n\
  \"heif\": \"${VERSION_HEIF}\",\n\
  \"imagequant\": \"${VERSION_IMAGEQUANT}\",\n\
  \"imagemagick\": \"${VERSION_MAGICK}\",\n\
  \"jpeg\": \"${VERSION_JPEG}\",\n\
  \"lcms\": \"${VERSION_LCMS2}\",\n\
  \"mozjpeg\": \"${VERSION_MOZJPEG}\",\n\
  \"orc\": \"${VERSION_ORC}\",\n\
  \"openjpeg\": \"${VERSION_OPENJPEG}\",\n\
  \"pango\": \"${VERSION_PANGO}\",\n\
  \"pixman\": \"${VERSION_PIXMAN}\",\n\
  \"poppler\": \"${VERSION_POPPLER}\",\n\
  \"png\": \"${VERSION_PNG16}\",\n\
  \"proxy-libintl\": \"${VERSION_PROXY_LIBINTL}\",\n\
  \"svg\": \"${VERSION_SVG}\",\n\
  \"spng\": \"${VERSION_SPNG}\",\n\
  \"tiff\": \"${VERSION_TIFF}\",\n\
  \"vips\": \"${VERSION_VIPS}\",\n\
  \"webp\": \"${VERSION_WEBP}\",\n\
  \"xml\": \"${VERSION_XML2}\",\n\
  \"zlib-ng\": \"${VERSION_ZLIB_NG}\"\n\
}" >versions.json

printf "\"${PLATFORM}\"" >platform.json

# Add third-party notices
$CURL -O https://raw.githubusercontent.com/tropy/sharp-libvips/master/THIRD-PARTY-NOTICES.md

# Create the tarball
rm -rf lib
mv lib-filtered lib
rm -f ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.{gz,br}
tar chzf ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz \
  include \
  lib \
  *.json \
  THIRD-PARTY-NOTICES.md

# Recompress using AdvanceCOMP, ~5% smaller
advdef --recompress --shrink-insane ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz

# Recompress using Brotli, ~15% smaller
gunzip -c ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz | brotli -o ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.br

# Allow tarballs to be read outside container
chmod 644 ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.*
