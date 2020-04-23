#!/bin/bash -ex

APP_ROOT=`pwd`

echo "Setting up RVM environment."
set +x
# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
set -x

gem install bundler -v '< 3.0' --no-document

# rename axis for Gemfile env var
export PUPPET_VERSION=$puppet

bundle install --jobs=5 --retry=5
bundle exec rake jenkins:unit
