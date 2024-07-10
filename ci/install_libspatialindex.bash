#!/bin/bash
set -xe

# A simple script to install libspatialindex from a Github Release
VERSION=2.0.0
SHA256=8caa4564c4592824acbf63a2b883aa2d07e75ccd7e9bf64321c455388a560579

# where to copy resulting files
# this has to be run before `cd`-ing anywhere
install_prefix() {
  OURPWD=$PWD
  cd "$(dirname "$0")"
  cd ../rtree
  arr=$(pwd)
  cd "$OURPWD"
  echo $arr
}

scriptloc() {
  OURPWD=$PWD
  cd "$(dirname "$0")"
  arr=$(pwd)
  cd "$OURPWD"
  echo $arr
}
# note that we're doing this convoluted thing to get
# an absolute path so mac doesn't yell at us
INSTALL_PREFIX=`install_prefix`
SL=`scriptloc`

rm -f $VERSION.zip
curl -LOs --retry 5 --retry-max-time 120 https://github.com/libspatialindex/libspatialindex/archive/${VERSION}.zip

# check the file hash
echo "${SHA256}  ${VERSION}.zip" | sha256sum -c -

rm -rf "libspatialindex-${VERSION}"
unzip -q $VERSION
cd libspatialindex-${VERSION}

mkdir build
cd build

printenv

if [ "$(uname)" == "Darwin" ]; then
    CMAKE_ARGS="-D CMAKE_OSX_ARCHITECTURES=${ARCHFLAGS##* } \
                -D CMAKE_INSTALL_RPATH=@loader_path"
fi

cmake ${CMAKE_ARGS} \
  -D CMAKE_BUILD_TYPE=Release \
  -D BUILD_SHARED_LIBS=ON \
  -D CMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
  -D CMAKE_INSTALL_LIBDIR=lib \
  -D CMAKE_PLATFORM_NO_VERSIONED_SONAME=ON \
  ..
make -j 4

# copy built libraries relative to path of this script
make install

# remove unneeded extras in lib
rm -rfv ${INSTALL_PREFIX}/lib/cmake
rm -rfv ${INSTALL_PREFIX}/lib/pkgconfig

ls -R ${INSTALL_PREFIX}/lib
ls -R ${INSTALL_PREFIX}/include
