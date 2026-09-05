#!/bin/bash -e
DIR=$( cd "$( dirname "$0" )" && pwd )

${DIR}/../apt.sh sshpass openssh-client
pip install -r ${DIR}/requirements.txt
