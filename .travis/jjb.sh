#!/bin/bash -xe

# Test JJB configs
for d in puppet/modules/jenkins_job_builder/files/theforeman.org; do
  ( cd $d && jenkins-jobs -l debug test -r . )
done

for d in puppet/modules/jenkins_job_builder/files/centos.org; do
  ( cd $d && jenkins-jobs -l debug test -r jobs )
done
