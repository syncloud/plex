#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

VERSION=$1

ARCH=$(uname -m)
DEB_ARCH=$(dpkg-architecture -q DEB_HOST_ARCH)
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download

apt update
apt install -y dpkg-dev wget

BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR

cd ${DIR}/build

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}

wget --progress=dot:giga https://downloads.plex.tv/plex-media-server-new/${VERSION}/debian/plexmediaserver_${VERSION}_${DEB_ARCH}.deb -O plexmediaserver.deb
ar x plexmediaserver.deb
tar xf data.tar.xz
find usr/lib/plexmediaserver -maxdepth 1 -type f | xargs -I {} cp {} ${BUILD_DIR}/bin
mv usr/lib/plexmediaserver/lib  ${BUILD_DIR}
mv usr/lib/plexmediaserver/Resources  ${BUILD_DIR}

