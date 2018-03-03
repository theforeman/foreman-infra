#!/bin/bash
[ -z "$ruby" ] && ruby=2.0.0

if [ -d foreman ];then
  cd foreman/
fi

# Clean npm modules
[ -d node_modules ] && rm -rf node_modules/

echo "Setting up RVM environment."
set +x
# Clean gemset and database
. /etc/profile.d/rvm.sh
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset}
set -x

# Env var works around Rails issue #28001 if DB migrations fail
bundle exec rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=true || true

echo "Delete gemset"
set +x
rvm gemset delete ${gemset} --force
set -x

exit 0
