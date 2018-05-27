#!/bin/bash -ex

plugin_name=katello

[ -e foreman ] && rm -rf foreman/
git clone https://github.com/theforeman/foreman --branch develop

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
#cd $APP_ROOT

# Katello specific setup
#cp ${PLUGIN_ROOT}/script/ci/katello.yml ${PLUGIN_ROOT}/config/katello.yml

#cd ${PLUGIN_ROOT}/engines/bastion_katello

#npm install https://github.com/Katello/bastion.git grunt


#grunt ci
#cd ${TOP_ROOT}

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

bundle install --without development --jobs=5 --retry=5

# Database environment
(
  sed "s/^test:/development:/; s/database:.*/database: ${gemset}-dev/" $HOME/postgresql.db.yaml
  echo
  sed "s/database:.*/database: ${gemset}-test/" $HOME/postgresql.db.yaml
) > $APP_ROOT/config/database.yml

# Create DB first in development as migrate behaviour can change
bundle exec rake db:drop db:create
### END test_develop ###

# Update dependencies
bundle update --jobs=5 --retry=5

# Now let's add the plugin migrations
#bundle exec rake db:migrate

cd $PLUGIN_ROOT
if [ -e package.json ];then
  npm install
  npm test
fi

# Katello-specific tests
cd $PLUGIN_ROOT/engines/bastion_katello
bundle install --jobs=5 --retry=5
bastion_install=`bundle show bastion`
cp -rf $bastion_install .
bastion_version=(${bastion_install//bastion-/ })
npm install npm
npm install
npm install bastion-${bastion_version[1]}/
grunt ci

cd $PLUGIN_ROOT
# Katello-specific tests
echo "**** Running Katello React Unit Tests ****"
if [ -e package.json ];then
  npm test
fi
