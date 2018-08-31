#!/bin/bash -xe

# Test JJB configs
for d in puppet/modules/jenkins_job_builder/files/theforeman.org; do
  ( cd $d && jenkins-jobs -l debug test -r . )
  ( cd $d && jenkins-jobs test -r . --config-xml -o output && git grep -l "project-type:.*pipeline" |xargs -n1 grep -m1 "name:" |cut -d: -f2 | xargs -n1 -I@@ python ../jenkins-lint.py --xml output/@@/config.xml && rm -rf output )
done

for d in puppet/modules/jenkins_job_builder/files/centos.org; do
  ( cd $d && jenkins-jobs -l debug test -r jobs )
  ( cd $d && jenkins-jobs test -r jobs --config-xml -o output && git grep -l "project-type:.*pipeline" |xargs -n1 grep -m1 "name:" |cut -d: -f2 | xargs -n1 -I@@ python ../jenkins-lint.py --xml output/@@/config.xml && rm -rf output )
done
