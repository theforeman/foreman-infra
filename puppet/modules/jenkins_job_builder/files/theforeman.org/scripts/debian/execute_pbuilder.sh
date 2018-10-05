#!/bin/bash
set -xe

# This script clones the git repos, cleans them up, and builds the package
echo "--Setting Up Sources"

# Setup the debian files, figure out the version
echo `git log -n1 --oneline`
cd debian/${os}/
VERSION=$(head -n1 ${project}/changelog|awk '{print $2}'|sed 's/(//;s/)//'|cut -f1 -d-)

# Setup sources
mkdir build-${project} && cd build-${project}
if [[ x$repo =~ ^xdevelop ]]; then
  url_base='https://ci.theforeman.org'
  job_name=$nightly_jenkins_job  # e.g. 'test_develop', from triggering job
  job_id=$nightly_jenkins_job_id # e.g. '123', from triggering
  json_url="${url_base}/job/${job_name}/${job_id}/api/json"

  # If a last* alias was used, resolve the numeric job ID
  job_id=$(curl "${json_url}" | /usr/local/bin/JSON.sh -b | awk '$1 == "[\"number\"]" { print $2 }')
  base_url=`curl "${json_url}" | /usr/local/bin/JSON.sh -b | awk '$1 ~ /^\["runs",.*,"number"\]/ && $2 == '$job_id' {getline; print $2; exit}' | tr -d \"`
  if [ x$base_url = x ] ; then
    base_url=`curl "${json_url}" | /usr/local/bin/JSON.sh -b | egrep '\["url"\]' | awk '{print $NF}' | tr -d \"`
  fi
  url="${base_url}/artifact/*zip*/archive.zip"

  wget $url
  unzip archive.zip
  mv archive/pkg/*bz2 ${project}_${VERSION}.orig.tar.bz2

  # Set this in case we need it
  LAST_COMMIT=`curl "${json_url}" | /usr/local/bin/JSON.sh -b | egrep '"lastBuiltRevision","SHA1"' | awk '{print $NF}' | tr -d \" | head -n1`
else
  VERSION=`echo ${VERSION} | tr '~rc' '-RC'`
  # Download sources
  wget http://downloads.theforeman.org/${project}/${project}-${VERSION}.tar.bz2
  wget http://downloads.theforeman.org/${project}/${project}-${VERSION}.tar.bz2.sig

  # Verify with packaging key - commented until we can handle multiple keys
#  tmp_keyring="./1AA043B8-keyring.gpg"
#  gpg --no-default-keyring --keyserver keys.gnupg.net --keyring $tmp_keyring --recv-keys 1AA043B8
#  if gpg --no-default-keyring --keyring $tmp_keyring ${project}-${VERSION}.tar.bz2.sig 2>&1 | grep -q "gpg: Good signature from \"Foreman Automatic Signing Key (2014) <packages@theforeman.org>\"" ; then
#    true # ok
#  else
#    exit 2
#  fi
  mv ${project}-${VERSION}.tar.bz2 ${project}_${VERSION}.orig.tar.bz2

  # Set this for test builds
  LAST_COMMIT=${VERSION}
fi

# Unpack
tar xvjf ${project}_${VERSION}.orig.tar.bz2
if [[ -d ${project}-${VERSION}-develop ]] ; then
	mv ${project}-${VERSION}-develop ${project}-${VERSION}
fi

# Bring in the debian packaging files
cp -r ../${project} ./${project}-${VERSION}/debian
cd ${project}-${VERSION}

# Add changelog entry if this is a git/nightly build
if [ x$gitrelease = xtrue ] || [ x$pr_number != x ]; then
  PACKAGE_NAME=$(head -n1 debian/changelog|awk '{print $1}')
  DATE=$(date -R)
  RELEASE="9999-${os}+scratchbuild+${BUILD_TIMESTAMP}"
  MAINTAINER="${repoowner} <no-reply@theforeman.org>"
  mv debian/changelog debian/changelog.tmp
  echo "$PACKAGE_NAME ($RELEASE) UNRELEASED; urgency=low

  * Automatically built package based on the state of
    foreman-packaging at commit $LAST_COMMIT

 -- $MAINTAINER  $DATE
" > debian/changelog

  cat debian/changelog.tmp >> debian/changelog
  rm -f debian/changelog.tmp

  # rename orig tarball to stop lintian complaining
  mv ../${project}_${VERSION}.orig.tar.bz2 ../${project}_9999.orig.tar.bz2
fi

# Build the package for the OS using pbuilder
# needs sudo as pedebuild uses loop and bind mounts
if [ $arch = x86 ]; then
  sudo pdebuild-${os}64
fi

# Only build on non-x86 arches when the binary differs
if grep -qe "Architecture:\s\+any" debian/control; then
  if [ $arch != x86 ]; then
    sudo pdebuild-${os}
  fi
fi

# Cleanup, pdebuild uses root
sudo chown -R jenkins:jenkins $WORKSPACE
