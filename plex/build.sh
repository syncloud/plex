#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

VERSION=$1

if [[ -z "$VERSION" ]]; then
    echo "usage $0 version"
    exit 1
fi

${DIR}/../apt.sh wget binutils xz-utils

DEB_ARCH=$(dpkg --print-architecture)
BUILD_DIR=${DIR}/../build/snap
mkdir -p ${BUILD_DIR}/bin

WORK_DIR=${DIR}/../build/plex
rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

${DIR}/../download-retry.sh https://downloads.plex.tv/plex-media-server-new/${VERSION}/debian/plexmediaserver_${VERSION}_${DEB_ARCH}.deb plexmediaserver.deb
ar x plexmediaserver.deb
tar xf data.tar.xz

find usr/lib/plexmediaserver -maxdepth 1 -type f | xargs -I {} cp {} ${BUILD_DIR}/bin
mv usr/lib/plexmediaserver/lib ${BUILD_DIR}
mv usr/lib/plexmediaserver/Resources ${BUILD_DIR}

rm -rf ${WORK_DIR}
