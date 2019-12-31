#!/bin/bash
set -e # dont rsync if clone fails
echo "Deploy started at `date`"
dir=`mktemp -d`
trap "rm -rf ${dir}" EXIT
git clone --recurse-submodules https://github.com/theforeman/foreman-infra ${dir}/
prod_dir="/etc/puppetlabs/code/environments/production"
module_dirs=(forge_modules git_modules modules)
for module_dir in "${module_dirs[@]}"
do
  rsync -aqx --delete-after --exclude=.git ${dir}/puppet/${module_dir}/ ${prod_dir}/${module_dir}
done
module_dirs_string=$(printf "%s:" "${module_dirs[@]}")
echo "modulepath = ${module_dirs_string}\$basemodulepath" >${prod_dir}/environment.conf
echo "Deploy complete at `date`"
