class deploy {
  secure_ssh::receiver_setup { 'deploy':
    user           => 'deploypuppet',
    foreman_search => 'host.name = slave01.rackspace.theforeman.org and name = external_ip4',
    script_content => template('deploy/script.erb'),
  }
}
