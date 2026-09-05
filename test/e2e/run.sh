#!/bin/bash -e

DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

ARTIFACT_SUBDIR=$1
SPEC=$2

export PLAYWRIGHT_APP_DOMAIN=plex.bookworm.com
export PLAYWRIGHT_DEVICE_HOST=plex.bookworm.com
export PLAYWRIGHT_SSH_USER=root
export PLAYWRIGHT_SSH_PASSWORD=Password1
export PLAYWRIGHT_ARTIFACT_DIR=/drone/src/artifact/${ARTIFACT_SUBDIR}
export PLAYWRIGHT_STATE_DIR=/drone/src/artifact

${DIR}/../../apt.sh sshpass openssh-client curl
${DIR}/wait-app.sh ${PLAYWRIGHT_APP_DOMAIN}
npm ci --no-audit --no-fund

for PLAYWRIGHT_PROJECT in desktop mobile; do
  export PLAYWRIGHT_PROJECT
  npx playwright test --project=${PLAYWRIGHT_PROJECT} "$SPEC"
done
