#!/bin/bash

ruby=2.4.3

# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem install brakeman --no-ri --no-rdoc

cp config/settings.yaml.example config/settings.yaml
brakeman -o brakeman_output.json --no-progress --separate-models
exit 0
