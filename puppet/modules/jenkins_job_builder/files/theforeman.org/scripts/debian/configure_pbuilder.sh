#!/bin/bash
set -xe

git checkout origin/deb/${repo} -b local || git checkout ${repo} -b local

# This script sets up the PBuilder hooks to pull in our deb repositories while the package is building
echo "--Apt Hook Setup"

# Cleanup any old hooks
sudo rm -f /etc/pbuilder/${os}64/hooks/F60addforemanrepo
sudo rm -f /etc/pbuilder/${os}32/hooks/F60addforemanrepo

if wget -O/dev/null -q http://stagingdeb.theforeman.org/dists/${os}/${repoowner}-${version} ; then
  echo "echo deb http://stagingdeb.theforeman.org/ ${os} ${repoowner}-${version} >> /etc/apt/sources.list" | sudo tee -a /etc/pbuilder/${os}64/hooks/F60addforemanrepo > /dev/null
  echo "echo deb http://stagingdeb.theforeman.org/ ${os} ${repoowner}-${version} >> /etc/apt/sources.list" | sudo tee -a /etc/pbuilder/${os}32/hooks/F60addforemanrepo > /dev/null
fi

# Use tee to get around sudo/redirection problems, with /dev/null to drop the stdout
echo "echo deb http://deb.theforeman.org/ ${os} ${version} >> /etc/apt/sources.list" | sudo tee -a /etc/pbuilder/${os}64/hooks/F60addforemanrepo > /dev/null
echo "echo deb http://deb.theforeman.org/ ${os} ${version} >> /etc/apt/sources.list" | sudo tee -a /etc/pbuilder/${os}32/hooks/F60addforemanrepo > /dev/null

# Permit per-OS/project setups to add their own repos
if [ -e debian/${os}/${project}/hooks ]; then
  sed "s/%OS%/${os}/g" debian/${os}/${project}/hooks | sudo tee -a /etc/pbuilder/${os}32/hooks/F60addforemanrepo
  sed "s/%OS%/${os}/g" debian/${os}/${project}/hooks | sudo tee -a /etc/pbuilder/${os}64/hooks/F60addforemanrepo
fi

# Make executable
sudo chmod 0775 /etc/pbuilder/${os}64/hooks/F60addforemanrepo
sudo chmod 0775 /etc/pbuilder/${os}32/hooks/F60addforemanrepo
