#!/bin/bash -ex

APP_ROOT=`pwd`

# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem install bundler --no-ri --no-rdoc

# rename axis for Gemfile env var
export PUPPET_VERSION=$puppet

bundle install --retry 5
bundle exec rake jenkins:unit
