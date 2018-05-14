#!/bin/bash -xe

echo "Setting up RVM environment."
set +x
# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
set -x

gem install bundler --no-ri --no-rdoc
bundle install --jobs=5 --retry=5

PAGER=/bin/cat git log | head -n 50
rake pkg:generate_source
