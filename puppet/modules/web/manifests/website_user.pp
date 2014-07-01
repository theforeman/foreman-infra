class web::website_user {

  # Disable password, we want this to be keys only
  user { 'website':
    ensure     => present,
    home       => '/home/website',
    managehome => true,
    password   => '!',
  }
  ->
  file { '/home/website/.ssh':
    ensure => directory,
    owner  => 'website',
    group  => 'website',
    mode   => 0700,
  }
  ->
  file { '/home/website/rsync_cache':
    ensure => directory,
    owner  => 'website',
    group  => 'website',
  }

  # Read the web key from the puppetmaster
  $pub_key  = ssh_keygen({name => 'web_key', public => 'public'})

  # Get the IPs of the Web Builder slaves from foreman
  $ip_data=foreman({
    'item'         => 'fact_values',
    'search'       => 'host = slave01.rackspace.theforeman.org and name = ipaddress',
    'foreman_user' => $::foreman_api_user,
    'foreman_pass' => $::foreman_api_password,
    })

  file { '/home/website/.ssh/authorized_keys':
    ensure  => present,
    owner   => 'website',
    group   => 'website',
    mode    => 0644,
    content => template('web/keys.erb'),
  }

  # Create validation script for rsync connections only
  file { '/home/website/bin':
    ensure => directory,
    owner   => 'website',
    group   => 'website',
    mode   => 0755,
  }

  file { '/home/website/bin/web_rsync':
    ensure  => present,
    owner   => 'website',
    group   => 'website',
    mode    => 0755,
    content => template('web/rsync.erb'),
  }
}
