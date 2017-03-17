#!/bin/bash -exl

APP_ROOT=`pwd`

# setup basic settings file
cp $APP_ROOT/config/settings.yml.example $APP_ROOT/config/settings.yml

# RVM Ruby environment
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem install bundler --no-ri --no-rdoc

# Puppet environment
sed -i "/^\s*gem.*puppet/ s/\$/, '~> $puppet'/" $APP_ROOT/bundler.d/puppet.rb

bundle install --without=development
bundle exec rake pkg:generate_source jenkins:unit
