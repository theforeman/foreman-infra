#!/bin/bash -ex

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

gem install bundler -v '< 2.0' --no-document

# Retry as rubygems (being external to us) can be intermittent
bundle install --without=development --jobs=5 --retry=5

# Rubocop
bundle exec rake rubocop

# setup UI testing

if [ "$database" = 'postgresql-integrations' ]; then
  export database='postgresql'
  export UI="true"
fi

# Database environment
(
  sed "s/^test:/development:/; s/database:.*/database: ${gemset}-dev/" $HOME/${database}.db.yaml
  echo
  sed "s/^test:/production:/; s/database:.*/database: ${gemset}-prod/" $HOME/${database}.db.yaml
  echo
  sed "s/database:.*/database: ${gemset}-test/" $HOME/${database}.db.yaml
) > $APP_ROOT/config/database.yml

# we need to install node modules for integration tests (which only run on postgresql)
if [ "${UI}" = "true" ]; then
  npm install
fi

# Create DB first in development as migrate behaviour can change
bundle exec rake db:drop || true
bundle exec rake db:create db:migrate --trace

tasks="pkg:generate_source jenkins:unit"
[ "${UI}" = "true" ] && tasks="jenkins:integration"
bundle exec rake $tasks TESTOPTS="-v" --trace

# Test asset precompile
if [ "${UI}" = "true" ]; then
  bundle exec rake db:drop RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=true || true
  bundle exec rake db:create RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=true
  bundle exec rake db:migrate RAILS_ENV=production
  bundle exec rake assets:precompile RAILS_ENV=production
  bundle exec rake webpack:compile RAILS_ENV=production
fi
