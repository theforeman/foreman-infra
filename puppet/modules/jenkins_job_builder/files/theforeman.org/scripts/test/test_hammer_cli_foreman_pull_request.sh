#!/bin/bash -ex

echo "Setting up RVM environment."
set +x
# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
set -x

gem update --no-ri --no-rdoc
gem install bundler -v '< 2.0' --no-ri --no-rdoc

# Link hammer_cli from github
if [ "$ghprbTargetBranch" = "master" ]; then
  echo 'gem "hammer_cli", :github => "theforeman/hammer-cli"' > Gemfile.local
fi

bundle install --without=development --jobs=5 --retry=5
bundle exec rake ci:setup:minitest test TESTOPTS="-v"
