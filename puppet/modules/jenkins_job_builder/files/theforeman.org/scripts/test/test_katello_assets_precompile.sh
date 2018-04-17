#!/bin/bash -ex

plugin_name=katello

[ -e foreman ] && rm -rf foreman/
git clone https://github.com/theforeman/foreman --branch "${base_foreman_branch}"

ruby=2.3

TOP_ROOT=`pwd`
APP_ROOT=$TOP_ROOT/foreman
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

# Now let's introduce the plugin
echo "gemspec :path => '${PLUGIN_ROOT}', :development_group => :katello_dev" >> bundler.d/Gemfile.local.rb

while ! bundle update -j 5; do
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle update continually failed" >&2
    exit 1
  fi
done

# Database environment
(
  sed "s/^test:/development:/; s/database:.*/database: ${gemset}-dev/" $HOME/postgresql.db.yaml
  sed "s/^test:/production:/; s/database:.*/database: ${gemset}-prod/" $HOME/postgresql.db.yaml
  echo
  sed "s/database:.*/database: ${gemset}-test/" $HOME/postgresql.db.yaml
) > $APP_ROOT/config/database.yml

bundle exec rails db:environment:set RAILS_ENV=production
bundle exec rake db:drop RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 || echo "FAILED Drop"
bundle exec rake db:create RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 || echo "FAILED Create"
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rake plugin:assets:precompile[katello] RAILS_ENV=production --trace
