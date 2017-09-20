#!/bin/bash -ex

APP_ROOT=`pwd`

# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
# Update any gems from the global gemset
# Don't update gems from the global gemset for Ruby 1.9*, io-console and json requires Ruby 2.0+
if [[ ${ruby} == 2* ]]; then
  gem update --no-ri --no-rdoc
fi
gem install bundler --no-ri --no-rdoc

# rename axis for Gemfile env var
export PUPPET_VERSION=$puppet

bundle install --retry 5
bundle exec rake jenkins:unit
