#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap

export PLEX_MEDIA_SERVER_HOME=${BUILD_DIR}
export LD_LIBRARY_PATH=${BUILD_DIR}/lib
export LC_ALL=C

"${BUILD_DIR}/bin/Plex Media Server" --version
