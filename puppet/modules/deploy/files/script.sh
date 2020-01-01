#!/bin/bash
set -e # dont rsync if clone fails
echo "Deploy started at `date`"
dir=`mktemp -d`
trap "rm -rf ${dir}" EXIT
git clone --recurse-submodules https://github.com/theforeman/foreman-infra ${dir}/
prod_dir="/etc/puppetlabs/code/environments/production"
rsync -aqx --delete-after --exclude=.git ${dir}/puppet/*modules ${prod_dir}/
echo 'modulepath = forge_modules:git_modules:modules:$basemodulepath' >${prod_dir}/environment.conf
echo "Deploy complete at `date`"
