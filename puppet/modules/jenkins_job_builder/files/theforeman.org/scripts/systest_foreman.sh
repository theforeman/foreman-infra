#!/bin/bash -xe

rm -f *.bats.out || true

if [ ${os} = f19 -o ${os} = f21 -o ${os} = f24 ]; then
  # https://github.com/mitchellh/vagrant-rackspace/issues/132
  echo "skipping f19/f21/f24, no Rackspace image"
  echo "1..0 # Skipped: no Rackspace image for f19/f21/f24" > skipped.bats.out
  exit 0
fi

if [ ${os#f} != $os ]; then
  [ $repo != nightly ] && FOREMAN_REPO=releases/$repo
  args="FOREMAN_REPO=$FOREMAN_REPO"
  [ $staging = true ] && args="FOREMAN_CUSTOM_URL=http://koji.katello.org/releases/yum/foreman-${repo}/Fedora/${os#f}/x86_64/ $args"
elif [ ${os#el} != $os ]; then
  [ $repo != nightly ] && FOREMAN_REPO=releases/$repo
  args="FOREMAN_REPO=$FOREMAN_REPO"
  [ $staging = true ] && args="FOREMAN_CUSTOM_URL=http://koji.katello.org/releases/yum/foreman-${repo}/RHEL/${os#el}/x86_64/ $args"
else
  if [ $staging = true ]; then
    args="FOREMAN_CUSTOM_URL=http://stagingdeb.theforeman.org/ FOREMAN_REPO=theforeman-${repo}"
  else
    args="FOREMAN_REPO=${repo}"
  fi
fi

if [ $run_hammer_tests = true ]; then
  args="FOREMAN_USE_ORGANIZATIONS=true FOREMAN_USE_LOCATIONS=true $args"
fi

if [ -n "${db_type}" ]; then
  args="FOREMAN_DB_TYPE=${db_type} $args"
fi

if [ -n "${expected_version}" ]; then
  args="FOREMAN_EXPECTED_VERSION=${expected_version} $args"
fi

[ $pl_puppet = true ] && pl_puppet=stable
[ $os = xenial -a $pl_puppet = stable ] && pl_puppet=false  # no repo available

export VAGRANT_DEFAULT_PROVIDER=rackspace

trap "vagrant destroy" EXIT ERR

PUPPET_REPO=${pl_puppet} vagrant up $os

# Workaround Rackspace image issue installing tzdata-java, as tzdata is pre-installed from
# jessie-updates and the two versions don't match. Can be removed after Debian 8.6 release.
if [ $os = jessie ]; then
  echo "echo 'deb http://httpredir.debian.org/debian jessie-updates main' >> /etc/apt/sources.list" | vagrant ssh $os
  echo "apt-get update" | vagrant ssh $os
fi

if [ -n "$umask" ]; then
  echo fb-setup-umask.bats | vagrant ssh $os | tee fb-setup-umask.bats.out
fi

if [ $pl_puppet != false ]; then
  echo PUPPET_REPO=${pl_puppet} fb-install-plpuppet.bats | vagrant ssh $os | tee fb-install-plpuppet.bats.out
fi

echo ${args} fb-install-foreman.bats | vagrant ssh $os | tee fb-install-foreman.bats.out

if [ $run_puppet_tests = true ]; then
  echo PUPPET_REPO=${pl_puppet} fb-puppet-tests.bats | vagrant ssh $os | tee fb-puppet-tests.bats.out
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
