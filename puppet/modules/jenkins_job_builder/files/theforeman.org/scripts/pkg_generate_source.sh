#!/bin/bash -xe

# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem install bundler --no-ri --no-rdoc

# Retry as rubygems (being external to us) can be intermittent
while ! bundle install -j 5; do
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle install continually failed" >&2
    exit 1
  fi
done

PAGER=/bin/cat git log | head -n 50
rake pkg:generate_source
