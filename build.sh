#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$2" ]]; then
    echo "usage $0 app version"
    exit 1
fi

NAME=$1
PLEX_VERSION=1.29.1.6276-4a96dd5b1


apt update
apt install -y dpkg-dev wget squashfs-tools dpkg-dev libltdl7

ARCH=$(uname -m)
DEB_ARCH=$(dpkg-architecture -q DEB_HOST_ARCH)
VERSION=$2
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download

BUILD_DIR=${DIR}/build/${NAME}
mkdir -p ${BUILD_DIR}

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}/

cp -r ${DIR}/bin ${BUILD_DIR}
cp -r ${DIR}/config ${BUILD_DIR}/config.templates
cp -r ${DIR}/hooks ${BUILD_DIR}

cd ${DIR}/build

wget --progress=dot:giga https://downloads.plex.tv/plex-media-server-new/${PLEX_VERSION}/debian/plexmediaserver_${PLEX_VERSION}_${DEB_ARCH}.deb -O plexmediaserver.deb
ar x plexmediaserver.deb
tar xf data.tar.xz
find usr/lib/plexmediaserver -maxdepth 1 -type f | xargs -I {} cp {} ${BUILD_DIR}/bin
mv usr/lib/plexmediaserver/lib  ${BUILD_DIR}
mv usr/lib/plexmediaserver/Resources  ${BUILD_DIR}

mkdir ${DIR}/build/${NAME}/META
echo ${NAME} >> ${DIR}/build/${NAME}/META/app
echo ${VERSION} >> ${DIR}/build/${NAME}/META/version

echo "snapping"
SNAP_DIR=${DIR}/build/snap
rm -rf ${DIR}/*.snap
mkdir ${SNAP_DIR}
cp -r ${BUILD_DIR}/* ${SNAP_DIR}/
cp -r ${DIR}/snap/meta ${SNAP_DIR}/
cp ${DIR}/snap/snap.yaml ${SNAP_DIR}/meta/snap.yaml
echo "version: $VERSION" >> ${SNAP_DIR}/meta/snap.yaml
echo "architectures:" >> ${SNAP_DIR}/meta/snap.yaml
echo "- ${DEB_ARCH}" >> ${SNAP_DIR}/meta/snap.yaml

PACKAGE=${NAME}_${VERSION}_${DEB_ARCH}.snap
echo ${PACKAGE} > ${DIR}/package.name
mksquashfs ${SNAP_DIR} ${DIR}/${PACKAGE} -noappend -comp xz -no-xattrs -all-root

mkdir ${DIR}/artifact
cp ${DIR}/${PACKAGE} ${DIR}/artifact
