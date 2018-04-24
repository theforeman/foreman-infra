#!/bin/bash -xe

# Test PR scanner configs
for f in puppet/modules/slave/templates/*.json.erb; do
  echo $f
  json_verify < $f
done

cd puppet
rake syntax
rake spec
