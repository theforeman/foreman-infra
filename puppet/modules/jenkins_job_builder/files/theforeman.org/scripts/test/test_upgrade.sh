#!/bin/bash -exl

git checkout origin/$old_branch

APP_ROOT=`pwd`

# setup basic settings file
sed -e 's/:locations_enabled: false/:locations_enabled: true/' $APP_ROOT/config/settings.yaml.example > $APP_ROOT/config/settings.yaml
sed -i 's/:organizations_enabled: false/:organizations_enabled: true/' $APP_ROOT/config/settings.yaml

# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
#gem update --no-ri --no-rdoc
gem install bundler --no-ri --no-rdoc

# Retry as rubygems (being external to us) can be intermittent
while ! bundle install --without=development -j5; do
  bundle clean --force || true
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle install continually failed" >&2
    exit 1
  fi
done

# Database environment
(
  sed "s/^test:/development:/; s/database:.*/database: ${gemset}-dev/" $HOME/${database}.db.yaml
  echo
  sed "s/database:.*/database: ${gemset}-test/" $HOME/${database}.db.yaml
) > $APP_ROOT/config/database.yml

# Create DB first in development as migrate behaviour can change
bundle exec rake db:drop db:create db:migrate
bundle exec rake db:seed

# Back to the pull request
git checkout -

# Retry as rubygems (being external to us) can be intermittent
while ! bundle update -j5; do
  bundle clean --force || true
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle update continually failed" >&2
    exit 1
  fi
done

bundle exec rake db:migrate
bundle exec rake db:seed
