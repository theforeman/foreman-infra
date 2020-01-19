#!/bin/bash
set -e # dont rsync if clone fails
echo "Deploy started at `date`"
dir=`mktemp -d`
trap "rm -rf ${dir}" EXIT
git clone --recurse-submodules https://github.com/theforeman/foreman-infra ${dir}/
rsync -aqx --delete-after --exclude=.git ${dir}/puppet/* /etc/puppetlabs/code/environments/production/
echo "Deploy complete at `date`"
