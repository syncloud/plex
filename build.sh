#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

VERSION=$1 # defined at the top of the .drone.jsonnet file now

apt update
apt install -y wget binutils xz-utils

ARCH=$(uname -m)
DEB_ARCH=$(dpkg --print-architecture)
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download
BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR
cd ${DIR}/build

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}

wget --progress=dot:giga https://downloads.plex.tv/plex-media-server-new/${VERSION}/debian/plexmediaserver_${VERSION}_${DEB_ARCH}.deb -O plexmediaserver.deb
ar x plexmediaserver.deb
tar xf data.tar.xz
mkdir -p $BUILD_DIR/bin
find usr/lib/plexmediaserver -maxdepth 1 -type f | xargs -I {} cp {} ${BUILD_DIR}/bin
mv usr/lib/plexmediaserver/lib  ${BUILD_DIR}
mv usr/lib/plexmediaserver/Resources  ${BUILD_DIR}

