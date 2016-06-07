#!/bin/bash
set -xe

# This script sets up the PBuilder hooks to pull in our deb repositories while the package is building
echo "--Apt Hook Setup"

for pbuilderd in /etc/pbuilder/${os}*; do
  # Cleanup any old hooks
  sudo rm -f ${pbuilderd}/hooks/F60addforemanrepo

  if wget -O/dev/null -q http://stagingdeb.theforeman.org/dists/${os}/${repoowner}-${version} ; then
    echo "echo deb http://stagingdeb.theforeman.org/ ${os} ${repoowner}-${version} >> /etc/apt/sources.list" | sudo tee -a ${pbuilderd}/hooks/F60addforemanrepo > /dev/null
  fi

  # Use tee to get around sudo/redirection problems, with /dev/null to drop the stdout
  echo "echo deb http://deb.theforeman.org/ ${os} ${version} >> /etc/apt/sources.list" | sudo tee -a ${pbuilderd}/hooks/F60addforemanrepo > /dev/null

  # Permit per-OS/project setups to add their own repos
  if [ -e debian/${os}/${project}/hooks ]; then
    sed "s/%OS%/${os}/g" debian/${os}/${project}/hooks | sudo tee -a ${pbuilderd}/hooks/F60addforemanrepo
  fi

  # Make executable
  sudo chmod 0775 ${pbuilderd}/hooks/F60addforemanrepo
  
  echo "tail -n 100 /etc/apt/sources.list /etc/apt/sources.list.d/*.list" | sudo tee ${pbuilderd}/hooks/F99printrepos
  sudo chmod 0775 ${pbuilderd}/hooks/F99printrepos
done
