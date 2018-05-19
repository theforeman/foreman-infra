#!/bin/bash -ex

APP_ROOT=`pwd`

# setup basic settings file
sed -e 's/:locations_enabled: false/:locations_enabled: true/' $APP_ROOT/config/settings.yaml.example > $APP_ROOT/config/settings.yaml
sed -i 's/:organizations_enabled: false/:organizations_enabled: true/' $APP_ROOT/config/settings.yaml

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

# Retry as rubygems (being external to us) can be intermittent
bundle install --without=development --jobs=5 --retry=5

# we need to install node modules for integration tests (which only run on postgresql)
if [ ${database} = postgresql -a -e "$APP_ROOT/package.json" ]; then
  npm install npm@'<6.0.0' # first upgrade to newer npm
  $APP_ROOT/node_modules/.bin/npm install
fi

# Database environment
(
  sed "s/^test:/development:/; s/database:.*/database: ${gemset}-dev/" $HOME/${database}.db.yaml
  echo
  sed "s/database:.*/database: ${gemset}-test/" $HOME/${database}.db.yaml
) > $APP_ROOT/config/database.yml

# Create DB first in development as migrate behaviour can change
bundle exec rake db:drop db:create db:migrate --trace

tasks="pkg:generate_source jenkins:unit"
[ ${database} = postgresql ] && tasks="$tasks jenkins:integration"
bundle exec rake $tasks TESTOPTS="-v" --trace
