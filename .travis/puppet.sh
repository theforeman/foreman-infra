#!/bin/bash -xe

cd puppet
mv forge_modules/* modules/
mv git_modules/* modules/
mv test_modules/* modules/
rake syntax
rake spec
