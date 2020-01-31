#!/bin/bash -xe

wget https://github.com/xorpaul/g10k/releases/download/v0.8.9/g10k-linux-amd64.zip
unzip g10k-linux-amd64.zip

./g10k -quiet -puppetfile -puppetfilelocation puppet/Puppetfile_forge -moduledir puppet/forge_modules

cd puppet
rake syntax
rake spec
