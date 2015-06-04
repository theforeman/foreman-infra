#!/bin/bash -ex
 
plugin_name=fusor
 
[ -e foreman ] && rm -rf foreman/
git clone https://github.com/theforeman/foreman --branch "${foreman_branch}"
 
[ -e katello ] && rm -rf katello/
git clone https://github.com/Katello/katello --branch "${katello_branch}"
 
 
 
TOP_ROOT=`pwd`
APP_ROOT=$TOP_ROOT/foreman
PLUGIN_ROOT=$TOP_ROOT/plugin
 
### PR testing ###
cd $PLUGIN_ROOT
if [ -n "${pr_git_url}" ]; then
  git remote add pr ${pr_git_url}
  git fetch pr
  git merge pr/${pr_git_ref}
fi
 
cd $APP_ROOT
 
### START test_develop ###
# This section is from test_develop, please keep it in sync
 
# setup basic settings file
sed -e 's/:locations_enabled: false/:locations_enabled: true/' $APP_ROOT/config/settings.yaml.example > $APP_ROOT/config/settings.yaml
sed -i 's/:organizations_enabled: false/:organizations_enabled: true/' $APP_ROOT/config/settings.yaml
 
# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem update --no-ri --no-rdoc
gem install bundler --no-ri --no-rdoc
 
# Now let's introduce the plugins
echo "gemspec :path => '${TOP_ROOT}/katello', :development_group => :katello_dev" >> bundler.d/Gemfile.local.rb
echo "gemspec :path => '${PLUGIN_ROOT}'" >> bundler.d/Gemfile.local.rb
 
# Retry as rubygems (being external to us) can be intermittent
while ! bundle install --without development -j 5; do
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
bundle exec rake db:drop db:create
### END test_develop ###
 
# Katello specific setup
cp ${TOP_ROOT}/katello/script/ci/katello.yml ${TOP_ROOT}/katello/config/katello.yml
 
# Update dependencies
while ! bundle update -j 5; do
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle update continually failed" >&2
    exit 1
  fi
done
 
# Now let's add the plugin migrations
bundle exec rake db:migrate
 
# Katello-specific tests
bundle exec rake test:fusor TESTOPTS="-v"
