#!/bin/bash -xe

# Test JJB configs
for d in puppet/modules/jenkins_job_builder/files/*; do
  cd $d
  jenkins-jobs -l debug test -r .
  cd -
done

# Test PR scanner configs
for f in puppet/modules/slave/templates/*.json.erb; do
  echo $f
  json_verify < $f
done

cd puppet
rake syntax
rake spec
