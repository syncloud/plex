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
SNAP_DIR=${DIR}/../build/snap
mkdir -p ${SNAP_DIR}
rm -rf ${SNAP_DIR}/plex

WORK_DIR=${DIR}/../build/plex
rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

${DIR}/../download-retry.sh https://downloads.plex.tv/plex-media-server-new/${VERSION}/debian/plexmediaserver_${VERSION}_${DEB_ARCH}.deb plexmediaserver.deb
ar x plexmediaserver.deb
tar xf data.tar.xz

mv usr/lib/plexmediaserver ${SNAP_DIR}/plex

cd ${DIR}
rm -rf ${WORK_DIR}
