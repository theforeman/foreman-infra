#!/bin/bash
[ -z "$ruby" ] && ruby=2.0.0

if [ -d foreman ];then
  cd foreman/
fi

# Clean npm modules
[ -d node_modules ] && rm -rf node_modules/

# Clean gemset and database
. /etc/profile.d/rvm.sh
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset}

# Workaround Rails issue #28001 if DB migrations fail, and ignore failures on older Rails versions
bundle exec rake db:environment:set >/dev/null 2>&1
bundle exec rake db:drop

rvm gemset delete ${gemset} --force
exit 0
