#!/bin/bash -xe

if [[ ! -f g10k ]] ; then
	if [[ ! -f g10k-linux-amd64 ]] ; then
		wget https://github.com/xorpaul/g10k/releases/download/v0.8.9/g10k-linux-amd64.zip
	fi
	unzip g10k-linux-amd64.zip
fi

./g10k -quiet -cachedir .g10k/cache -puppetfile -puppetfilelocation puppet/Puppetfile_forge -moduledir puppet/forge_modules

cd puppet
bundle exec rake syntax
bundle exec rake lint
bundle exec rake spec
