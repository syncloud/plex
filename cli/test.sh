#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

HOOKS=${DIR}/../build/snap/meta/hooks
BIN=${DIR}/../build/snap/bin

${HOOKS}/install --help
${HOOKS}/configure --help
${HOOKS}/pre-refresh --help
${HOOKS}/post-refresh --help
${BIN}/cli --help
