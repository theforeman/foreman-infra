#!/bin/bash -ex

APP_ROOT=`pwd`

# setup basic settings file
cp $APP_ROOT/config/settings.yml.example $APP_ROOT/config/settings.yml

echo "Setting up RVM environment."
set +x
# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
set -x

# Update any gems from the global gemset
#gem update --no-ri --no-rdoc
gem install bundler -v '< 2.0' --no-ri --no-rdoc

# Puppet environment
if [ -e $APP_ROOT/bundler.d/puppet.rb ] ; then
	sed -i "/^\s*gem.*puppet/ s/\$/, '~> $puppet'/" $APP_ROOT/bundler.d/puppet.rb
fi

bundle install --without=development --jobs=5 --retry=5
bundle exec rake pkg:generate_source jenkins:unit
