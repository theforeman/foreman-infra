class deploy {
  secure_ssh::receiver_setup { 'deploy':
    user           => 'deploypuppet',
    foreman_search => '(host.name = slave01.rackspace.theforeman.org or host.name = slave02.rackspace.theforeman.org) and (name = external_ip4 or name = external_ip6)',
    script_content => template('deploy/script.erb'),
  }
}
