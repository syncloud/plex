#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo ${DIR}/usr/lib/*-linux-gnu*)
LOADER=$(ls ${DIR}/lib/*-linux-gnu*/ld-linux*)
exec ${LOADER} --library-path $LIBS ${DIR}/usr/sbin/nginx "$@"
