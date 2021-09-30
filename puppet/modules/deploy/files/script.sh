#!/bin/bash
set -e # dont rsync if clone fails
echo "Deploy started at `date`"
dir=`mktemp -d`
environment=production
trap "rm -rf ${dir}" EXIT
git clone --recurse-submodules https://github.com/theforeman/foreman-infra ${dir}/
g10k -quiet -puppetfile -puppetfilelocation ${dir}/puppet/Puppetfile_forge -moduledir ${dir}/puppet/forge_modules
rsync -aqx --delete-after --exclude=.git ${dir}/puppet/* /etc/puppetlabs/code/environments/$environment/
puppet generate types --environment $environment
echo "Deploy complete at `date`"
