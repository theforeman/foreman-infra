#!/bin/bash -xe

base_dir=/var/www/vhosts/downloads/htdocs/discovery

cd aux/vagrant-build

export distro=f27
export proxy_repo=$(eval echo ${proxy_repository})
export VAGRANT_DEFAULT_PROVIDER=openstack
trap "vagrant destroy ${distro}" EXIT ERR

# execute the build
vagrant up ${distro} --provision
vagrant ssh-config ${distro} | tee vagrant-ssh-config.tmp
mkdir -p tmp
rm -rf tmp/*
scp -F vagrant-ssh-config.tmp ${distro}:foreman-discovery-image/fdi*tar tmp/
scp -F vagrant-ssh-config.tmp ${distro}:foreman-discovery-image/fdi-bootable*iso tmp/

# delete old files in the target folder
ssh root@web02.theforeman.org "mkdir -p ${base_dir}/${output_dir}/ ; rm -f ${base_dir}/${output_dir}/*" || true

# publish on web
scp tmp/* root@web02.theforeman.org:${base_dir}/${output_dir}/
rm -rf tmp/*

# create symlinks
ssh root@web02.theforeman.org "pushd ${base_dir}/releases/ && rm -f latest; ln -sf \$(ls -t | head -1) latest; popd" || true
ssh root@web02.theforeman.org "pushd ${base_dir}/${output_dir}/ && ln -sf fdi*tar fdi-image-latest.tar && popd" || true

# create sums
ssh root@web02.theforeman.org "pushd ${base_dir}/${output_dir}/ && md5sum * > MD5SUMS; popd" || true

