#!/bin/bash -ex

APP_ROOT=`pwd`

# setup basic settings file
cp $APP_ROOT/config/settings.yml.example $APP_ROOT/config/settings.yml

set +x
# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
set -x

# Update any gems from the global gemset
gem update --no-document
gem install bundler -v '< 2.0' --no-document

bundle install --with=test --without='development puppet windows bmc' --retry 5 --jobs 5
bundle exec rake jenkins:rubocop TESTOPTS="-v"
