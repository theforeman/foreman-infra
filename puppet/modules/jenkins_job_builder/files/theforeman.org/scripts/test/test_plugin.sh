#!/bin/bash -ex

TOP_ROOT=`pwd`
APP_ROOT=$TOP_ROOT/foreman
PLUGIN_ROOT=$TOP_ROOT/plugin

cd $APP_ROOT

### START test_develop ###
# This section is from test_develop, please keep it in sync

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
while ! bundle install --without=development -j5; do
  bundle clean --force || true
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle install continually failed" >&2
    exit 1
  fi
done

# we need to install node modules for integration tests
if [ -e "$APP_ROOT/package.json" ]; then
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
bundle exec rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=true --trace
# We drop and create in 2 separate commands (speed penalty, 2 Rails initializations)
# as it's necessary to make sure at db:migrate models are loaded from a clean slate.
# e.g: model Host isn't loaded with a 'type' attribute before the column is added
# in the migration.
bundle exec rake db:create db:migrate DISABLE_DATABASE_ENVIRONMENT_CHECK=true --trace

### END test_develop ###

# Ensure we don't mention the gem twice in the Gemfile in case it's already mentioned there
find Gemfile bundler.d -type f -exec sed -i "/gem ['\"]${plugin_name}['\"]/d" {} \;
# Now let's introduce the plugin
echo "gem '${plugin_name}', :path => '${PLUGIN_ROOT}'" >> bundler.d/Gemfile.local.rb

# Plugin specifics..
[ -e ${PLUGIN_ROOT}/gemfile.d/${plugin_name}.rb ] && cat ${PLUGIN_ROOT}/gemfile.d/${plugin_name}.rb >> bundler.d/Gemfile.local.rb

# Update dependencies
while ! bundle update; do
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle update continually failed" >&2
    exit 1
  fi
done

# Now let's add the plugin migrations
bundle exec rake db:migrate RAILS_ENV=development --trace

tasks="jenkins:unit"
[ ${database} = postgresql ] && tasks="$tasks jenkins:integration"
bundle exec rake $tasks TESTOPTS="-v" --trace

# Run the DB seeds to verify they work
bundle exec rake db:drop db:create db:migrate --trace
bundle exec rake db:seed --trace
