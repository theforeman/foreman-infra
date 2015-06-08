#!/bin/bash -xe

rm -f *.bats.out || true

if [ ${os} = f19 ]; then
  # https://github.com/mitchellh/vagrant-rackspace/issues/132
  echo "skipping f19, no Rackspace image"
  echo "1..0 # Skipped: no Rackspace image for f19" > skipped.bats.out
  exit 0
fi

if [ ${os#f} != $os ]; then
  osname=Fedora
  osver=${os#f}
  [ $repo != nightly ] && FOREMAN_REPO=releases/$repo
  args="FOREMAN_CUSTOM_URL=http://koji.katello.org/releases/yum/foreman-${repo}/${osname}/${osver}/x86_64/ FOREMAN_REPO=$FOREMAN_REPO"
elif [ ${os#el} != $os ]; then
  osname=RHEL
  osver=${os#el}
  [ $repo != nightly ] && FOREMAN_REPO=releases/$repo
  args="FOREMAN_CUSTOM_URL=http://koji.katello.org/releases/yum/foreman-${repo}/${osname}/${osver}/x86_64/ FOREMAN_REPO=$FOREMAN_REPO"
else
  args="FOREMAN_CUSTOM_URL=http://stagingdeb.theforeman.org/ FOREMAN_REPO=theforeman-${repo}"
fi

if [ $run_hammer_tests = true ]; then
  args="FOREMAN_USE_ORGANIZATIONS=true FOREMAN_USE_LOCATIONS=true $args"
fi

export VAGRANT_DEFAULT_PROVIDER=rackspace

trap "vagrant destroy" EXIT ERR

vagrant up $os

PUPPET_REPO=stable
[ $nightly_puppet = true ] && PUPPET_REPO=nightly
if [ $pl_puppet = true -a ! $os = jessie -o $os = precise ]; then
  echo PUPPET_REPO=${PUPPET_REPO} fb-install-plpuppet.bats | vagrant ssh $os | tee fb-install-plpuppet.bats.out
fi

echo ${args} fb-install-foreman.bats | vagrant ssh $os | tee fb-install-foreman.bats.out

if [ $run_puppet_tests = true ]; then
  echo fb-puppet-tests.bats | vagrant ssh $os | tee fb-puppet-tests.bats.out
fi

if [ $run_hammer_tests = true ]; then
  if [ "x$hammer_deps" != "x" ]; then
    echo "cd ~/ && wget https://gist.githubusercontent.com/tstrachota/52b86d7ccf835a11dc99/raw/install_gems.sh" | vagrant ssh $os
    hammer_deps=$(echo -e $hammer_deps | tr "\n" " ")
    echo "Hammer deps: ${hammer_deps}"
    echo "bash ~/install_gems.sh ${hammer_deps}" | vagrant ssh $os
  fi

  hammer_test_args="HAMMER_TEST_BRANCH=${hammer_tests_branch}"
  hammer_test_args="HAMMER_TEST_REPO=https://github.com/${hammer_tests_owner}/hammer-tests.git ${hammer_test_args}"
  echo $hammer_test_args fb-hammer-tests.bats | vagrant ssh $os | tee fb-hammer-tests.bats.out
fi

[ -e debug ] && rm -rf debug/
mkdir debug
vagrant ssh-config $os > ssh_config
scp -F ssh_config ${os}:/root/last_logs debug/ || true
scp -F ssh_config ${os}:/root/sosreport* debug/ || true
scp -F ssh_config ${os}:/root/foreman-debug* debug/ || true
scp -F ssh_config ${os}:/root/hammer_test_logs/* debug/ || true

exit 0
