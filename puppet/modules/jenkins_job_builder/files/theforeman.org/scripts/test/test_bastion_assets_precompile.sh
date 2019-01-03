#!/bin/bash -ex

plugin_name=bastion

[ -e foreman ] && rm -rf foreman/
git clone https://github.com/theforeman/foreman --branch "${base_foreman_branch}"

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
gem install bundler -v '< 2.0' --no-ri --no-rdoc

# Now let's introduce the plugin
echo "gemspec :path => '${PLUGIN_ROOT}', :development_group => :bastion_dev" >> bundler.d/Gemfile.local.rb

bundle install --without development --jobs=5 --retry=5

# Database environment
#(
#  sed "s/^test:/development:/; s/database:.*/database: ${gemset}-dev/" $HOME/database.db.yaml
#  echo
#  sed "s/database:.*/database: ${gemset}-test/" $HOME/database.db.yaml
#) > $APP_ROOT/config/database.yml

#touch $APP_ROOT/config/database.yml

cp $APP_ROOT/config/database.yml.example $APP_ROOT/config/database.yml

# Update dependencies
bundle update --jobs=5 --retry=5

bundle exec rake plugin:assets:precompile[bastion] --trace
