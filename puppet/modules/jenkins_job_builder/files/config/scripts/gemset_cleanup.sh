#!/bin/bash
ruby=2.0.0
# Clean gemset and database
. /etc/profile.d/rvm.sh
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset}
rvm gemset delete ${gemset} --force
exit 0
