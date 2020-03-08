#!/bin/bash
set -e

# Working directories
DEPS=/deps
TARGET=/target
mkdir ${DEPS}
mkdir ${TARGET}

# Common build paths and flags
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${TARGET}/lib/pkgconfig"
export PATH="${PATH}:${TARGET}/bin"
export CPPFLAGS="-I${TARGET}/include"
export LDFLAGS="-L${TARGET}/lib"
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"

# Dependency version numbers
#VERSION_ZLIB=1.2.11
#VERSION_FFI=3.3
#VERSION_GLIB=2.63.2
#VERSION_XML2=2.9.10
#VERSION_GSF=1.14.46
VERSION_EXIF=0.6.21
VERSION_LCMS2=2.9
VERSION_JPEG=2.0.4
VERSION_JP2=2.3.1
VERSION_PNG16=1.6.37
VERSION_WEBP=1.1.0
VERSION_TIFF=4.1.0
#VERSION_ORC=0.4.29
#VERSION_GETTEXT=0.20.1
#VERSION_GDKPIXBUF=2.40.0
#VERSION_FREETYPE=2.10.1
#VERSION_EXPAT=2.2.8
#VERSION_FONTCONFIG=2.13.92
#VERSION_HARFBUZZ=2.6.1
#VERSION_PIXMAN=0.38.4
#VERSION_CAIRO=1.17.2
#VERSION_FRIBIDI=1.0.5
#VERSION_PANGO=1.42.4
#VERSION_SVG=2.64.4
VERSION_GIF=5.1.4
VERSION_POPPLER=0.86.1
#VERSION_POPPLER_DATA=0.4.9
VERSION_HEIF=1.5.1
VERSION_DE265=1.0.3
VERSION_IMAGEMAGICK="6.9.11-0"

# Remove patch version component
without_patch() {
  echo "$1" | sed "s/\.[0-9]*$//"
}

# Check for newer versions
ALL_AT_VERSION_LATEST=true
version_latest() {
  VERSION_LATEST=$(curl -s https://release-monitoring.org/api/project/$3 | jq -r '.versions[]' | grep -E -m1 '^[0-9]+(.[0-9]+)*$')
  if [ "$VERSION_LATEST" != "$2" ]; then
    ALL_AT_VERSION_LATEST=false
    echo "$1 version $2 has been superseded by $VERSION_LATEST"
  fi
}
#version_latest "zlib" "$VERSION_ZLIB" "5303"
#version_latest "ffi" "$VERSION_FFI" "1611"
#version_latest "glib" "$VERSION_GLIB" "10024" # latest version requires meson instead of autotools
#version_latest "xml2" "$VERSION_XML2" "1783"
#version_latest "gsf" "$VERSION_GSF" "1980"
version_latest "exif" "$VERSION_EXIF" "1607"
version_latest "lcms2" "$VERSION_LCMS2" "9815"
version_latest "jpeg" "$VERSION_JPEG" "1648"
version_latest "png" "$VERSION_PNG16" "1705"
version_latest "webp" "$VERSION_WEBP" "1761"
version_latest "tiff" "$VERSION_TIFF" "13521"
#version_latest "orc" "$VERSION_ORC" "2573"
#version_latest "gettext" "$VERSION_GETTEXT" "898"
#version_latest "gdkpixbuf" "$VERSION_GDKPIXBUF" "9533" # latest version requires meson instead of autotools
#version_latest "freetype" "$VERSION_FREETYPE" "854"
#version_latest "expat" "$VERSION_EXPAT" "770"
#version_latest "fontconfig" "$VERSION_FONTCONFIG" "827"
#version_latest "harfbuzz" "$VERSION_HARFBUZZ" "1299"
#version_latest "pixman" "$VERSION_PIXMAN" "3648"
#version_latest "cairo" "$VERSION_CAIRO" "247" # latest version in release monitoring does not exist
#version_latest "fribidi" "$VERSION_FRIBIDI" "857"
#version_latest "pango" "$VERSION_PANGO" "11783" # latest version requires meson instead of autotools
#version_latest "svg" "$VERSION_SVG" "5420" latest version fails to link against latest cairo
#version_latest "gif" "$VERSION_GIF" "1158" # v5.1.5+ provides a Makefile only so will require custom cross-compilation setup
version_latest "poppler" "$VERSION_POPPLER" "3686"
#version_latest "poppler-data" "$VERSION_POPPLER_DATA" "3687"
if [ "$ALL_AT_VERSION_LATEST" = "false" ]; then exit 1; fi

# Download and build dependencies from source

#case ${PLATFORM} in *musl*)
#  mkdir ${DEPS}/gettext
#  curl -Ls https://ftp.gnu.org/pub/gnu/gettext/gettext-${VERSION_GETTEXT}.tar.xz | tar xJC ${DEPS}/gettext --strip-components=1
#  cd ${DEPS}/gettext
#  ./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
#  make install-strip
#  rm ${TARGET}/include/gettext-po.h
#  rm -rf ${TARGET}/lib/*gettext*
#esac

#mkdir ${DEPS}/zlib
#curl -Ls https://zlib.net/zlib-${VERSION_ZLIB}.tar.xz | tar xJC ${DEPS}/zlib --strip-components=1
#cd ${DEPS}/zlib
#./configure --prefix=${TARGET} --uname=linux
#make install
#rm ${TARGET}/lib/libz.a

#mkdir ${DEPS}/ffi
#curl -Ls https://sourceware.org/pub/libffi/libffi-${VERSION_FFI}.tar.gz | tar xzC ${DEPS}/ffi --strip-components=1
#cd ${DEPS}/ffi
#sed -i 's/@toolexeclibdir@/$(libdir)/g' Makefile.in
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking --disable-builddir
#make install-strip

#mkdir ${DEPS}/glib
#curl -Lks https://download.gnome.org/sources/glib/$(without_patch $VERSION_GLIB)/glib-${VERSION_GLIB}.tar.xz | tar xJC ${DEPS}/glib --strip-components=1
#cd ${DEPS}/glib
#echo glib_cv_stack_grows=no >>glib.cache
#echo glib_cv_uscore=no >>glib.cache
#./configure --cache-file=glib.cache --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
#  --with-pcre=internal --disable-libmount
#make install-strip

#mkdir ${DEPS}/xml2
#curl -Ls http://xmlsoft.org/sources/libxml2-${VERSION_XML2}.tar.gz | tar xzC ${DEPS}/xml2 --strip-components=1
#cd ${DEPS}/xml2
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
#  --without-python --without-debug --without-docbook --without-ftp --without-html --without-legacy \
#  --without-pattern --without-push --without-regexps --without-schemas --without-schematron --with-zlib=${TARGET}
#make install-strip

#mkdir ${DEPS}/gsf
#curl -Lks https://download.gnome.org/sources/libgsf/$(without_patch $VERSION_GSF)/libgsf-${VERSION_GSF}.tar.xz | tar xJC ${DEPS}/gsf --strip-components=1
#cd ${DEPS}/gsf
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
#  --without-bz2 --without-gdk-pixbuf
#make install-strip

mkdir ${DEPS}/exif
curl -Ls https://sourceforge.mirrorservice.org/l/li/libexif/libexif/${VERSION_EXIF}/libexif-${VERSION_EXIF}.tar.bz2 | tar xjC ${DEPS}/exif --strip-components=1
cd ${DEPS}/exif
autoreconf -fiv
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/lcms2
curl -Ls https://sourceforge.mirrorservice.org/l/lc/lcms/lcms/${VERSION_LCMS2}/lcms2-${VERSION_LCMS2}.tar.gz | tar xzC ${DEPS}/lcms2 --strip-components=1
cd ${DEPS}/lcms2
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/jpeg
curl -Ls https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${VERSION_JPEG}.tar.gz | tar xzC ${DEPS}/jpeg --strip-components=1
cd ${DEPS}/jpeg
cmake -G"Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=/root/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=${TARGET}/lib \
  -DENABLE_SHARED=TRUE -DENABLE_STATIC=FALSE -DWITH_JPEG8=1 -DWITH_TURBOJPEG=FALSE
make install/strip

mkdir ${DEPS}/png16
curl -Ls https://sourceforge.mirrorservice.org/l/li/libpng/libpng16/${VERSION_PNG16}/libpng-${VERSION_PNG16}.tar.xz | tar xJC ${DEPS}/png16 --strip-components=1
cd ${DEPS}/png16
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/webp
curl -Ls https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${VERSION_WEBP}.tar.gz | tar xzC ${DEPS}/webp --strip-components=1
cd ${DEPS}/webp
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --disable-neon --enable-libwebpmux
make install-strip

mkdir ${DEPS}/tiff
curl -Ls https://download.osgeo.org/libtiff/tiff-${VERSION_TIFF}.tar.gz | tar xzC ${DEPS}/tiff --strip-components=1
cd ${DEPS}/tiff
if [ -n "${CHOST}" ]; then autoreconf -fiv; fi
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking --disable-mdi --disable-pixarlog --disable-cxx
make install-strip

#mkdir ${DEPS}/orc
#curl -Ls https://gstreamer.freedesktop.org/data/src/orc/orc-${VERSION_ORC}.tar.xz | tar xJC ${DEPS}/orc --strip-components=1
#cd ${DEPS}/orc
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
#make install-strip
#cd ${TARGET}/lib
#rm -rf liborc-test-*

#mkdir ${DEPS}/gdkpixbuf
#curl -Lks https://download.gnome.org/sources/gdk-pixbuf/$(without_patch $VERSION_GDKPIXBUF)/gdk-pixbuf-${VERSION_GDKPIXBUF}.tar.xz | tar xJC ${DEPS}/gdkpixbuf --strip-components=1
#cd ${DEPS}/gdkpixbuf
#touch gdk-pixbuf/loaders.cache
#LD_LIBRARY_PATH=${TARGET}/lib \
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
#  --disable-introspection --disable-modules \
#  --without-libtiff --without-gdiplus --with-included-loaders=png,jpeg
#make install-strip

#mkdir ${DEPS}/freetype
#curl -Ls ${SOURCEFORGE_BASE_URL}freetype/freetype2/${VERSION_FREETYPE}/freetype-${VERSION_FREETYPE}.tar.gz | tar xzC ${DEPS}/freetype --strip-components=1
#cd ${DEPS}/freetype
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
#  --without-bzip2
#make install

#mkdir ${DEPS}/expat
#curl -Ls ${SOURCEFORGE_BASE_URL}expat/expat/${VERSION_EXPAT}/expat-${VERSION_EXPAT}.tar.bz2 | tar xjC ${DEPS}/expat --strip-components=1
#cd ${DEPS}/expat
#sed -i "s/getrandom/ignore_getrandom/g" configure # https://github.com/libexpat/libexpat/issues/239
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static \
#  --disable-dependency-tracking --without-xmlwf --without-docbook
#make install

#mkdir ${DEPS}/fontconfig
#curl -Ls https://www.freedesktop.org/software/fontconfig/release/fontconfig-${VERSION_FONTCONFIG}.tar.xz | tar xJC ${DEPS}/fontconfig --strip-components=1
#cd ${DEPS}/fontconfig
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
#  --with-expat-includes=${TARGET}/include --with-expat-lib=${TARGET}/lib --sysconfdir=/etc --disable-docs
#make install-strip

#mkdir ${DEPS}/harfbuzz
#curl -Ls https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-${VERSION_HARFBUZZ}.tar.xz | tar xJC ${DEPS}/harfbuzz --strip-components=1
#cd ${DEPS}/harfbuzz
#sed -i "s/error   \"-Wunused-local-typedefs\"/ignored \"-Wunused-local-typedefs\"/" src/hb.hh
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
#make install-strip
#rm ${TARGET}/lib/libharfbuzz-subset*

#mkdir ${DEPS}/pixman
#curl -Ls http://cairographics.org/releases/pixman-${VERSION_PIXMAN}.tar.gz | tar xzC ${DEPS}/pixman --strip-components=1
#cd ${DEPS}/pixman
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking --disable-libpng --disable-arm-iwmmxt
#make install-strip

#mkdir ${DEPS}/cairo
#curl -Ls http://cairographics.org/snapshots/cairo-${VERSION_CAIRO}.tar.xz | tar xJC ${DEPS}/cairo --strip-components=1
#cd ${DEPS}/cairo
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
#  --disable-xlib --disable-xcb --disable-quartz --disable-win32 --disable-egl --disable-glx --disable-wgl \
#  --disable-script --disable-ps --disable-trace --disable-interpreter
#make install-strip

#mkdir ${DEPS}/fribidi
#curl -Ls https://github.com/fribidi/fribidi/releases/download/v${VERSION_FRIBIDI}/fribidi-${VERSION_FRIBIDI}.tar.bz2 | tar xjC ${DEPS}/fribidi --strip-components=1
#cd ${DEPS}/fribidi
#autoreconf -fiv
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
#make install-strip

#mkdir ${DEPS}/pango
#curl -Lks https://download.gnome.org/sources/pango/$(without_patch $VERSION_PANGO)/pango-${VERSION_PANGO}.tar.xz | tar xJC ${DEPS}/pango --strip-components=1
#cd ${DEPS}/pango
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
#  --without-gtk-doc
#make install-strip

#mkdir ${DEPS}/svg
#curl -Lks https://download.gnome.org/sources/librsvg/$(without_patch $VERSION_SVG)/librsvg-${VERSION_SVG}.tar.xz | tar xJC ${DEPS}/svg --strip-components=1
#cd ${DEPS}/svg
## Optimise Rust code for binary size
#sed -i "s/debug = true/debug = false\ncodegen-units = 1\nincremental = false\npanic = \"abort\"\nopt-level = ${RUST_OPT_LEVEL:-\"s\"}/" Cargo.toml
#./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
#  --disable-introspection --disable-tools --disable-pixbuf-loader
#make install-strip
## Clear executable bit from librsvg shared library for WSL support
#execstack -c ${TARGET}/lib/librsvg-2.so || true

mkdir ${DEPS}/gif
curl -Ls https://sourceforge.mirrorservice.org/g/gi/giflib/giflib-${VERSION_GIF}.tar.gz | tar xzC ${DEPS}/gif --strip-components=1
cd ${DEPS}/gif
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir -p ${DEPS}/openjpeg/build
curl -Ls https://github.com/uclouvain/openjpeg/archive/v${VERSION_JP2}.tar.gz | tar xzC ${DEPS}/openjpeg --strip-components=1
cd ${DEPS}/openjpeg/build
cmake .. -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=/root/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=${TARGET}/lib \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
make install/strip

#mkdir ${DEPS}/poppler-data
#curl -Ls https://poppler.freedesktop.org/poppler-data-${VERSION_POPPLER_DATA}.tar.gz | tar xzC ${DEPS}/poppler-data --strip-components=1
#cd ${DEPS}/poppler-data
#make install prefix=${TARGET}

mkdir -p ${DEPS}/poppler/build
curl -Ls https://poppler.freedesktop.org/poppler-${VERSION_POPPLER}.tar.xz | tar xJC ${DEPS}/poppler --strip-components=1
cd ${DEPS}/poppler/build
# Skip building and linking pdf-fullrewrite binary!
sed -i "s/add_subdirectory(test)//" ../CMakeLists.txt
cmake .. -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=/root/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=${TARGET}/lib \
  -DBUILD_SHARED_LIBS=ON -DENABLE_GLIB=ON \
  -DENABLE_SPLASH=OFF -DENABLE_UTILS=OFF -DENABLE_QT5=OFF -DENABLE_CPP=OFF \
  -DENABLE_LIBCURL=OFF -DENABLE_ZLIB_UNCOMPRESS=ON -DENABLE_GOBJECT_INTROSPECTION=OFF -DENABLE_LIBOPENJPEG=openjpeg2 \
  -DBUILD_GTK_TESTS=OFF -DBUILD_QT5_TESTS=OFF -DBUILD_CPP_TESTS=OFF
make install/strip

mkdir ${DEPS}/de265
curl -Ls https://github.com/strukturag/libde265/releases/download/v${VERSION_DE265}/libde265-${VERSION_DE265}.tar.gz | tar xzC ${DEPS}/de265 --strip-components=1
cd ${DEPS}/de265
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --disable-dec265 --disable-sherlock265
make install-strip

mkdir ${DEPS}/heif
curl -Ls https://github.com/strukturag/libheif/releases/download/v${VERSION_HEIF}/libheif-${VERSION_HEIF}.tar.gz | tar xzC ${DEPS}/heif --strip-components=1
cd ${DEPS}/heif
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --disable-examples --disable-go --disable-gdk-pixbuf
make install-strip

mkdir ${DEPS}/imagemagick
curl -Ls https://imagemagick.org/download/ImageMagick-${VERSION_IMAGEMAGICK}.tar.gz | tar xzC ${DEPS}/imagemagick --strip-components=1
cd ${DEPS}/imagemagick
./configure \
  --host=${CHOST} \
  --prefix=${TARGET} \
  --enable-shared \
  --disable-static \
  --disable-dependency-tracking \
  --disable-largefile \
  --disable-openmp \
  --with-openjp2 \
  --without-fontconfig \
  --without-freetype \
  --without-gvc \
  --without-heic \
  --without-lqr \
  --without-lzma \
  --without-magick-plus-plus \
  --without-modules \
  --without-openexr \
  --without-pango \
  --without-rsvg \
  --without-webp \
  --without-x \
  --without-xml \
  --without-zlib
make install-strip

mkdir ${DEPS}/vips
curl -Ls https://github.com/libvips/libvips/releases/download/v${VERSION_VIPS}/vips-${VERSION_VIPS}.tar.gz | tar xzC ${DEPS}/vips --strip-components=1
cd ${DEPS}/vips
./configure \
  --host=${CHOST} \
  --prefix=${TARGET} \
  --enable-shared \
  --disable-static \
  --disable-dependency-tracking \
  --disable-debug \
  --disable-introspection \
  --without-OpenEXR \
  --without-analyze \
  --without-cfitsio \
  --without-gsf \
  --without-imagequant \
  --without-matio \
  --without-nifti \
  --without-openslide \
  --without-pangoft2 \
  --without-pdfium \
  --without-ppm \
  --without-radiance \
  --without-x \
  --with-heif \
  --with-libwebp \
  --with-magick \
  --with-poppler \
  --with-rsvg \
  --with-tiff \
  --with-png-includes=${TARGET}/include --with-png-libraries=${TARGET}/lib \
  --with-giflib-includes=${TARGET}/include --with-giflib-libraries=${TARGET}/lib \
  --with-jpeg-includes=${TARGET}/include --with-jpeg-libraries=${TARGET}/lib
make install-strip

# Create JSON file of version numbers
cd ${TARGET}
printf "{\n\
  \"de265\": \"${VERSION_DE265}\",\n\
  \"exif\": \"${VERSION_EXIF}\",\n\
  \"fftw\": \"$(pkg-config --modversion fftw3)\",\n\
  \"fontconfig\": \"$(pkg-config --modversion fontconfig)\",\n\
  \"freetype\": \"$(pkg-config --modversion freetype2)\",\n\
  \"gdkpixbuf\": \"$(pkg-config --modversion gdk-pixbuf-2.0)\",\n\
  \"gif\": \"${VERSION_GIF}\",\n\
  \"glib\": \"$(pkg-config --modversion glib-2.0)\",\n\
  \"heif\": \"${VERSION_HEIF}\",\n\
  \"jpeg\": \"${VERSION_JPEG}\",\n\
  \"lcms\": \"${VERSION_LCMS2}\",\n\
  \"imagemagick\": \"${VERSION_IMAGEMAGICK}\",\n\
  \"openjpeg\": \"${VERSION_JP2}\",\n\
  \"orc\": \"$(pkg-config --modversion orc-0.4)\",\n\
  \"png\": \"${VERSION_PNG16}\",\n\
  \"pixman\": \"$(pkg-config --modversion pixman-1)\",\n\
  \"svg\": \"$(pkg-config --modversion librsvg-2.0)\",\n\
  \"tiff\": \"${VERSION_TIFF}\",\n\
  \"vips\": \"${VERSION_VIPS}\",\n\
  \"webp\": \"${VERSION_WEBP}\",\n\
  \"xml\": \"$(pkg-config --modversion libxml-2.0)\"\n\
}" >versions.json

printf "\"${PLATFORM}\"" >platform.json

# Pack only the relevant shared libraries
#mkdir ${TARGET}/x-lib
#cd ${TARGET}/lib
#cp -L libvips-cpp.so.42 ${TARGET}/x-lib
#while read dep; do
#  cp -L $dep ${TARGET}/x-lib/$dep
#  echo lib/$dep
#done < <(ldd libvips-cpp.so.42 | grep ${TARGET}/lib | cut -d '=' -f1 | awk '{print $1}')
#
#cd ${TARGET}
#rm -rf lib
#mv x-lib lib

# Remove the old C++ bindings
cd ${TARGET}/include
rm -rf vips/vipsc++.h vips/vipscpp.h
cd ${TARGET}/share
rm -rf pkgconfig
cd ${TARGET}/lib
rm -rf pkgconfig .libs *.la libvipsCC* cmake

# Set RPATH to $ORIGIN
find ${TARGET}/lib -type f -name "*.so*" -exec sh -c "patchelf --set-rpath '\$ORIGIN' --force-rpath {}" \;

# Create .tar.gz
cd ${TARGET}
tar czf /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz include lib *.json
advdef --recompress --shrink-insane /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz
