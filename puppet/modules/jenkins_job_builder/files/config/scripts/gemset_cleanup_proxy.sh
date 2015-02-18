#!/bin/bash -e
# Clean RVM Ruby environment
. /etc/profile.d/rvm.sh
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}
rvm gemset delete ${gemset} --force
