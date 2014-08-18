class deploy {
  # Adapted from secure_rsync for a pure ssh solution
  $user           = 'deploypuppet'
  $homedir        = '/home/deploypuppet'
  $foreman_search = 'host.name = slave01.rackspace.theforeman.org and name = ipaddress'

  # Disable password, we want this to be keys only
  user { $user:
    ensure     => present,
    home       => $homedir,
    managehome => true,
    password   => '!',
  }
  ->
  file { "${homedir}/.ssh":
    ensure => directory,
    owner  => $user,
    mode   => '0700',
  }

  # Read the web key from the puppetmaster
  $pub_key  = ssh_keygen({name => 'deploy_key', public => 'public'})

  if $foreman_search {
    # Get the IPs of the admin slave from foreman
    $ip_data=foreman({
      'item'         => 'fact_values',
      'search'       => $foreman_search,
      'foreman_user' => $::foreman_api_user,
      'foreman_pass' => $::foreman_api_password,
      })
  }

  file { "${homedir}/.ssh/authorized_keys":
    ensure  => present,
    owner   => $user,
    mode    => '0700',
    content => template('deploy/auth_keys.erb'),
  }

  # Create validation script for rsync connections only
  file { "${homedir}/bin":
    ensure => directory,
    owner  => $user,
    mode   => '0700',
  }

  file { "${homedir}/bin/deploy_puppet":
    ensure  => present,
    owner   => $user,
    mode    => '0700',
    content => template('deploy/script.erb'),
  }
}
