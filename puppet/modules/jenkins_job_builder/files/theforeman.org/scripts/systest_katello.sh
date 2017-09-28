#!/bin/bash -xe

rm -f *.bats.out || true

os_vagrant='centos7-katello-bats-ci'
cp -f boxes.yaml.example boxes.yaml

export VAGRANT_DEFAULT_PROVIDER=rackspace

trap "vagrant destroy $os_vagrant" EXIT ERR

vagrant up $os_vagrant || true

[ -e debug ] && rm -rf debug/
mkdir debug
vagrant ssh-config $os_vagrant > ssh_config
scp -F ssh_config $os_vagrant:/root/bats_results/*.tap debug/ || true
scp -F ssh_config $os_vagrant:/root/last_logs debug/ || true
scp -F ssh_config $os_vagrant:/root/sosreport* debug/ || true
scp -F ssh_config $os_vagrant:/root/foreman-debug.tar.xz debug/
scp -F ssh_config $os_vagrant:/var/log/foreman-installer/katello.log* debug/ || true

exit 0
