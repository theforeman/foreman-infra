#!/bin/bash
set -xe

# Script to copy the newly-built debs to the web node for signing and promoting
# Dependencies
# * the freight::client class in foreman-infra
# * the web node must have the freight class applied

# Find the deps in the build-dir from the previous step
DEB_PATH=./dependencies/${os}/build-${project}

# Upload all builds to stagingdeb for testing
echo "scratch build: uploading to stagingdeb/${os}/${repoowner}-${version}"
export RSYNC_RSH="ssh -i /home/jenkins/workspace/staging_key/rsync_freightstage_key"
USER=freightstage
HOSTS=web02.rackspace web01.osuosl
COMPONENT=${repoowner}-${version}

for HOST in HOSTS; do
  # The path is important, as freight_rsync (which is run on the web node for incoming
  # transfers) will parse the path to figure out the repo to send debs to.
  TARGET_PATH="${USER}@${HOST}.theforeman.org:rsync_cache/${os}/${COMPONENT}/"

  if ls $DEB_PATH/*deb >/dev/null 2>&1; then
    /usr/bin/rsync -avPx $DEB_PATH/*deb $TARGET_PATH
  fi
done
