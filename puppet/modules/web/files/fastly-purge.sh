#!/bin/bash

set -e
set -o pipefail

BASE=${1}
shift

for purge in $@; do
  curl --silent -X PURGE -H 'Fastly-Saft-Purge:1' ${BASE}/${purge}
done
