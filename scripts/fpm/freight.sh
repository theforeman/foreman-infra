#!/bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root."
  exit 1
fi

set -x

export FREIGHT_GIT='https://github.com/rcrowley/freight.git'
export GIT=`which git`
export TMP_DIR='/tmp/freight_build'

if [ -e freight ]; then
  echo "The freight directory already exists. Updating..."
  cd freight && git pull
  cd ../
else
  echo "Clone the freight repository..."
  $GIT clone $FREIGHT_GIT
fi

gem install fpm --no-ri --no-rdoc

if [ -e $TMP_DIR ]; then
  echo "Removing the old tmp directory..."
  rm -rf $TMP_DIR
fi

mkdir -p $TMP_DIR

cd freight
export VERSION=`git describe --abbrev=0 --tags |  cut -c2-6`
git checkout v$VERSION
"Installing Freight $VERSION to $TMP_DIR..."
make install DESTDIR=$TMP_DIR

cd ../

if [ -z "`echo *.rpm`" ]; then
  rm *.rpm
fi

echo "Building the package with FPM..."
/usr/bin/fpm -s dir -t rpm -n freight -v $VERSION -C $TMP_DIR \
    -d "dpkg" usr/local
