#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

PLEX_DIR=${DIR}/../build/snap/plex

unset LD_LIBRARY_PATH

"${PLEX_DIR}/Plex Media Server" --version
"${PLEX_DIR}/Plex Tuner Service" --version
"${PLEX_DIR}/Plex Transcoder" -version > /dev/null
