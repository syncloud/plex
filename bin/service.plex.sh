#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

if [[ -z "$1" ]]; then
    echo "usage $0 [start]"
    exit 1
fi

export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=$SNAP_DATA/Application_Support
export PLEX_MEDIA_SERVER_HOME=$DIR
export PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
export PLEX_MEDIA_SERVER_INFO_VENDOR="Syncloud"
export PLEX_MEDIA_SERVER_INFO_DEVICE="Syncloud"
export PLEX_MEDIA_SERVER_INFO_MODEL=$(uname -m)
export PLEX_MEDIA_SERVER_INFO_PLATFORM_VERSION=""
export LD_LIBRARY_PATH=$DIR/lib

case $1 in
start)
    if [ ! -d "${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR}" ]; then
      mkdir -p "${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR}"
    fi
    exec "$DIR/bin/Plex Media Server"
    ;;
*)
    echo "not valid command"
    exit 1
    ;;
esac
