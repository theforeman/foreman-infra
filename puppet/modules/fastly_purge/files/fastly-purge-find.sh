#!/bin/bash

set -e
set -o pipefail

URLBASE=${1}
BASEDIR=${2}
PURGE=${3}

pushd $BASEDIR
  find $PURGE -type f | xargs --no-run-if-empty fastly-purge "${URLBASE}"
popd
