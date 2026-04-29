#!/bin/bash -e
DIR=$( cd "$( dirname "$0" )" && pwd )

apt-get update
apt-get install -y sshpass openssh-client
pip install -r requirements.txt