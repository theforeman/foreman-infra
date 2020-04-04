#!/bin/bash
set -e # dont rsync if clone fails
echo "Deploy started at `date`"
dir=`mktemp -d`
trap "rm -rf ${dir}" EXIT
git clone https://github.com/theforeman/foreman-infra ${dir}/
git --git-dir ${dir}/.git submodule update --init -- puppet/git_modules
g10k -quiet -puppetfile -puppetfilelocation ${dir}/puppet/Puppetfile_forge -moduledir ${dir}/puppet/forge_modules
rsync -aqx --delete-after --exclude=.git ${dir}/puppet/* /etc/puppetlabs/code/environments/production/
echo "Deploy complete at `date`"
