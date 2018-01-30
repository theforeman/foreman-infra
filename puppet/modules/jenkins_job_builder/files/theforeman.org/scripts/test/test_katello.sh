#!/bin/bash -ex

TOP_ROOT=`pwd`
if [ -e $TOP_ROOT/foreman/Gemfile ]; then
  APP_ROOT=$TOP_ROOT/foreman
else
  APP_ROOT=$TOP_ROOT
fi
PLUGIN_ROOT=$TOP_ROOT/plugin

### Foreman PR testing ###
cd $APP_ROOT
if [ -n "${foreman_pr_git_url}" ]; then
  git remote add pr ${foreman_pr_git_url}
  git fetch pr
  git merge pr/${foreman_pr_git_ref}
fi

### PR testing ###
cd $PLUGIN_ROOT
if [ -n "${pr_git_url}" ]; then
  git remote add pr ${pr_git_url}
  git fetch pr
  git merge pr/${pr_git_ref}
fi

cd $APP_ROOT
mkdir config/settings.plugins.d

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

gem update --no-ri --no-rdoc
gem install bundler --no-ri --no-rdoc

# Now let's introduce the plugin
echo "gemspec :path => '${PLUGIN_ROOT}', :development_group => :katello_dev" >> bundler.d/Gemfile.local.rb
echo "gem 'psych'" >> bundler.d/Gemfile.local.rb

# Retry as rubygems (being external to us) can be intermittent
while ! bundle update -j 5; do
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle update continually failed" >&2
    exit 1
  fi
done

# Database environment
(
  sed "s/^test:/development:/; s/database:.*/database: ${gemset}-dev/" $HOME/${database}.db.yaml
  echo
  sed "s/database:.*/database: ${gemset}-test/" $HOME/${database}.db.yaml
) > $APP_ROOT/config/database.yml

# First try to drop the DB, but ignore failure as it might happen with Rails 5
# when there is really no DB yet.
bundle exec rake db:drop || true

# Create DB first in development as migrate behaviour can change
bundle exec rake db:create --trace
### END test_develop ###

# Now let's add the plugin migrations
bundle exec rake db:migrate --trace

# Katello-specific tests
bundle exec rake jenkins:katello TESTOPTS="-v" --trace

# Run the DB seeds to verify they work
# Don't run DB seeds if the version of katello is less than 3.1
VERSION=$(grep -Po "(\d+\.)+\d+" ${PLUGIN_ROOT}/lib/katello/version.rb)

if [ $(echo ${VERSION}$'\n3.1.0' | sort --version-sort --reverse | head -n1) != '3.1.0' ]; then
  bundle exec rake db:drop || true
  bundle exec rake db:create db:migrate --trace
  bundle exec rake db:seed --trace
fi

# Clean up the database after use
bundle exec rake db:drop || true

cd $PLUGIN_ROOT

rm -rf pkg/
mkdir pkg
gem build katello.gemspec
cp katello-*.gem pkg/
