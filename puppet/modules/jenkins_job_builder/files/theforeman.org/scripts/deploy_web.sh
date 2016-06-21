#!/bin/bash -xe

# Build the site on the slave 

ruby=2.3.0
# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
#gem update --no-ri --no-rdoc
gem install bundler --no-ri --no-rdoc

# Retry as rubygems (being external to us) can be intermittent
while ! bundle install -j 5; do
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle install continually failed" >&2
    exit 1
  fi
done

# compile site on slave
bundle exec jekyll build 

# Copy the site to the web node
# Dependencies
# * the slave must have the web::uploader class
# * the web node must have the web class

# Sync to the pivot-point on the web node
TARGET_PATH="website@theforeman.org:rsync_cache/"

# Export this to avoid quoting issues
export RSYNC_RSH="ssh -i /var/lib/workspace/workspace/rsync_web_key"

/usr/bin/rsync -acvxz --delete-after ./_site/ $TARGET_PATH
