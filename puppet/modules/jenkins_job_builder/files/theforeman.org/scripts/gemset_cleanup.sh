#!/bin/bash
[ -z "$ruby" ] && ruby=2.0.0

if [ -d foreman ];then
  cd foreman/
fi

# Clean gemset and database
. /etc/profile.d/rvm.sh
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset}
bundle exec rake db:drop
rvm gemset delete ${gemset} --force
exit 0
