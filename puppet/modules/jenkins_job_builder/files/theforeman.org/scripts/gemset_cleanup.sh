#!/bin/bash -exl
[ -z "$ruby" ] && ruby=2.0.0

if [ -d foreman ];then
  cd foreman/
fi

# Clean npm modules
[ -d node_modules ] && rm -rf node_modules/

# Clean gemset and database
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset}

# Env var works around Rails issue #28001 if DB migrations fail
bundle exec rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=true

rvm gemset delete ${gemset} --force
exit 0
