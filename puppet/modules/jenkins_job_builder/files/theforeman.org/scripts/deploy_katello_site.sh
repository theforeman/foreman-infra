#!/bin/bash -xe

# Reset environment
rm -rf public/
git checkout deploy
git reset origin/deploy --hard

./deploy.rb

data_dir=$(ssh -i '/var/lib/workspace/workspace/deploy_katello_repos_key/deploy_katello_repos_key' 53fe3c0b5973ca67f1000266@site-katelloproject.rhcloud.com 'echo $OPENSHIFT_DATA_DIR')
rsync --delete-after -rvzhe 'ssh -i /var/lib/workspace/workspace/deploy_katello_repos_key/deploy_katello_repos_key' public/ 53fe3c0b5973ca67f1000266@site-katelloproject.rhcloud.com:/$data_dir/public

