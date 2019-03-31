#!/bin/bash
set -xe

# This script clones the git repos, cleans them up, and builds the package
echo "--Setting Up Sources"

# Setup the debian files
cd plugins
mkdir build-${project}
cd build-${project}
cp -r ../${project} ./
cd ${project}
../../download_gems

# Add changelog entry if this is a git/nightly build
if [ x$gitrelease = xtrue ] || [ x$pr_number != x ]; then
  PACKAGE_NAME=$(head -n1 debian/changelog|awk '{print $1}')
  DATE=$(date -R)
  BUILD_TIMESTAMP=$(date +%Y%m%d%H%M%S)
  RELEASE="9999-plugin+scratchbuild+${BUILD_TIMESTAMP}"
  MAINTAINER="${repoowner} <no-reply@theforeman.org>"
  mv debian/changelog debian/changelog.tmp
  echo "$PACKAGE_NAME ($RELEASE) UNRELEASED; urgency=low

  * Automatically built package based on the state of
    foreman-packaging at commit $LAST_COMMIT

 -- $MAINTAINER  $DATE
" > debian/changelog

  cat debian/changelog.tmp >> debian/changelog
  rm -f debian/changelog.tmp
fi

# Build plugin
sudo pdebuild-${os}64

# Cleanup, pdebuild uses root
sudo chown -R jenkins:jenkins $WORKSPACE
