#!/bin/bash -xe

cd puppet
mv forge_modules/* modules/
rake syntax
rake spec
