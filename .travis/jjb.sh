#!/bin/bash -xe

# Test JJB configs
for d in puppet/modules/jenkins_job_builder/files/*; do
  ( cd $d && jenkins-jobs -l debug test -r . )
done
