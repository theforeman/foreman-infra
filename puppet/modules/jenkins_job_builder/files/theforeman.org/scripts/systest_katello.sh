#!/bin/bash -xe

rm -f *.bats.out || true

osname=RHEL
osver="${os#el}"
args="FOREMAN_CUSTOM_URL=http://koji.katello.org/releases/yum/${repo}/${osname}/${osver}/x86_64/"

if [ ${os} = el6 ]; then
 os_vagrant='centos6-bats'
else
 os_vagrant='centos7-bats'
fi

export VAGRANT_DEFAULT_PROVIDER=rackspace

trap "vagrant destroy $os_vagrant" EXIT ERR

vagrant up $os_vagrant
vagrant ssh $os_vagrant -c "ls -la /vagrant"
vagrant ssh $os_vagrant -c "USE_KOJI_REPOS=true katello-bats swapfile nightly content" | tee fb-install-foreman.bats.out

[ -e debug ] && rm -rf debug/
mkdir debug
vagrant ssh-config $os_vagrant > ssh_config
scp -F ssh_config $os_vagrant:/root/last_logs debug/ || true
scp -F ssh_config $os_vagrant:/root/sosreport* debug/ || true
scp -F ssh_config $os_vagrant:/root/foreman-debug* debug/ || true
scp -F ssh_config $os_vagrant:/var/log/foreman-installer/katello.log* debug/ || true

exit 0
