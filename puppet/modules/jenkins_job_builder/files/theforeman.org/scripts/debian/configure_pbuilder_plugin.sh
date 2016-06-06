#!/bin/bash
set -xe

# This script sets up the PBuilder hooks to pull in our deb repositories while the package is building
echo "--Apt Hook Setup"

# Cleanup any old hooks
sudo rm -f /etc/pbuilder/${os}64/hooks/F60addforemanrepo

if [ x$repoowner != xtheforeman ]; then
  # Add a stagingdeb repo to the sources too, if it exists
  if wget -O/dev/null -q http://stagingdeb.theforeman.org/dists/${os}/${repoowner}-${version} ; then
    echo "echo deb http://stagingdeb.theforeman.org/ ${os} ${repoowner}-${version} >> /etc/apt/sources.list" | sudo tee -a /etc/pbuilder/${os}64/hooks/F60addforemanrepo > /dev/null
  fi
  if wget -O/dev/null -q http://stagingdeb.theforeman.org/dists/plugins/${repoowner} ; then
    echo "echo deb http://stagingdeb.theforeman.org/ plugins ${repoowner} >> /etc/apt/sources.list" | sudo tee -a /etc/pbuilder/${os}64/hooks/F60addforemanrepo > /dev/null
  fi
fi

# Use tee to get around sudo/redirection problems, with /dev/null to drop the stdout
echo "echo deb http://deb.theforeman.org/ ${os} ${version} >> /etc/apt/sources.list" | sudo tee -a /etc/pbuilder/${os}64/hooks/F60addforemanrepo > /dev/null
echo "echo deb http://deb.theforeman.org/ plugins ${version} >> /etc/apt/sources.list" | sudo tee -a /etc/pbuilder/${os}64/hooks/F60addforemanrepo > /dev/null

# Read Foreman package installation logs on failure
echo "cat /var/log/foreman-install.log" | sudo tee /etc/pbuilder/${os}64/hooks/C10foremanlog

# Make executable
sudo chmod 0775 /etc/pbuilder/${os}64/hooks/*
