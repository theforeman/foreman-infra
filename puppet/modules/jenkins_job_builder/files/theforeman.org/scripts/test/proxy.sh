#!/bin/bash -ex

APP_ROOT=`pwd`

# setup basic settings file
cp $APP_ROOT/config/settings.yml.example $APP_ROOT/config/settings.yml

# Puppet environment
sed -i "/^\s*gem.*puppet/ s/\$/, '~> $puppet'/" $APP_ROOT/bundler.d/puppet.rb

bundle install --without=development
bundle exec rake pkg:generate_source jenkins:unit
