#!/bin/bash -ex

git checkout origin/$old_branch

APP_ROOT=`pwd`

# setup basic settings file
cp $APP_ROOT/config/settings.yaml.example $APP_ROOT/config/settings.yaml

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

# Retry as rubygems (being external to us) can be intermittent
bundle install --without=development --jobs=5 --retry=5

# Database environment
(
  sed "s/^test:/development:/; s/database:.*/database: ${gemset}-dev/" $HOME/${database}.db.yaml
  echo
  sed "s/database:.*/database: ${gemset}-test/" $HOME/${database}.db.yaml
) > $APP_ROOT/config/database.yml

# Create DB first in development as migrate behaviour can change
bundle exec rake db:drop --trace
bundle exec rake db:create db:migrate --trace
bundle exec rake db:seed --trace

# Back to the pull request
git checkout -

# Retry as rubygems (being external to us) can be intermittent
bundle update --jobs=5 --retry=5

bundle exec rake db:migrate --trace
bundle exec rake db:seed --trace
