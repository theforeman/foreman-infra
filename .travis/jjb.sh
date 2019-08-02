#!/bin/bash -xe

# Test JJB configs
for d in puppet/modules/jenkins_job_builder/files/theforeman.org; do
  DIR="."
  ( cd $d && jenkins-jobs -l debug test -r $DIR )
  ( cd $d && jenkins-jobs test -r $DIR --config-xml -o output && find output -name config.xml -exec python ../jenkins-lint.py --xml {} + && rm -rf output )
done

for d in puppet/modules/jenkins_job_builder/files/centos.org; do
  DIR="jobs"
  ( cd $d && jenkins-jobs -l debug test -r $DIR )
  ( cd $d && jenkins-jobs test -r $DIR --config-xml -o output && find output -name config.xml -exec python ../jenkins-lint.py --xml {} + && rm -rf output )
done
