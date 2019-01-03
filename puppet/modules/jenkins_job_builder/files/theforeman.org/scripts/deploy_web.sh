#!/bin/bash -xe

# Build the site on the slave

echo "Setting up RVM environment."
# RVM Ruby environment
set +x
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
set -x

gem install bundler -v '< 2.0' --no-ri --no-rdoc
bundle install --jobs=5 --retry=5

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

/usr/bin/rsync --archive --checksum --verbose --one-file-system --compress --stats --progress --delete-after ./_site/ $TARGET_PATH
