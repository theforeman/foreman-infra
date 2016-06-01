#!/bin/bash -xe

# Build the site on the slave 
ruby=2.0.0
# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
#gem update --no-ri --no-rdoc
gem install bundler --no-ri --no-rdoc

# Reset environment
rm -rf public/
git checkout deploy
git reset origin/deploy --hard

./deploy.rb

data_dir=$(ssh 53fe3c0b5973ca67f1000266@site-katelloproject.rhcloud.com 'echo $OPENSHIFT_DATA_DIR')
rsync --delete-after -avzhe 'ssh -i /var/lib/workspace/workspace/deploy_katello_repos_key/deploy_katello_repos_key' public/ 53fe3c0b5973ca67f1000266@site-katelloproject.rhcloud.com/:/$data_dir
