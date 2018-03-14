#!/bin/bash -xe

if [[ -z $os ]] ; then
	echo "Operating system not set"
	exit 1
fi

box_name="systest-foreman-${os}${BUILD_NUMBER:+-$BUILD_NUMBER}"
filename="boxes.d/80-tmp-${box_name}.yaml"

args=""

if [[ $run_hammer_tests == true ]]; then
  args+=" --foreman-organizations-enabled=true --foreman-locations-enabled=true"
fi

if [[ -n "${db_type}" ]]; then
  args+=" --foreman-db-type=${db_type}"
fi

cat > "$filename" <<-EOF
${box_name}:
  box: ${os}
  domain: 'rackspace.theforeman.org'
  synced_folders:
    - path: /vagrant
      mount_point: /vagrant
      options:
        disabled: true
  ansible:
    playbook: 'playbooks/bats_pipeline_foreman_nightly.yml'
    group: 'bats'
    variables:
      bats_environment:
      - FOREMAN_EXPECTED_VERSION: ${expected_version}
      ${args:+foreman_installer_options:${args}}
      ${umask:+umask_mode: ${umask}}
      ${repo:+foreman_repositories_version: ${repo}}
      ${repo_environment:+foreman_repositories_environment: ${repo_environment}}
      ${pl_puppet:+puppet_repositories_version: ${pl_puppet}}
      ${run_hammer_tests:+foreman_testing_hammer_tests: ${run_hammer_tests}}
EOF

if [[ $os == debian9 ]] ; then
	# The Debian 9 image on rackspace has no /usr/bin/python
	echo "      ansible_python_interpreter: /usr/bin/python2.7" >> "$filename"
fi

export VAGRANT_DEFAULT_PROVIDER=openstack

trap "vagrant destroy $box_name" EXIT ERR

vagrant up $box_name || true

[ -e debug ] && rm -rf debug/
mkdir debug
cp "$filename" debug/
vagrant ssh-config $box_name > ssh_config
scp -F ssh_config ${box_name}:/root/bats_results/*.tap debug/ || true
scp -F ssh_config ${box_name}:/root/last_logs debug/ || true
scp -F ssh_config ${box_name}:/root/sosreport* debug/ || true
scp -F ssh_config ${box_name}:/root/foreman-debug* debug/ || true
if [[ $run_hammer_tests == true ]] ; then
  scp -F ssh_config ${box_name}:/root/hammer_test_logs/* debug/ || true
fi

exit 0
