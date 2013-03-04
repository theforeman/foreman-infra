class freight::user (
  $user = 'freight',
  $home = '/srv/freight',
) {

  # Disable password, we want this to be keys only
  user { $user:
    ensure     => present,
    home       => $home,
    managehome => true,
    password   => '!',
  }

  file { $home:
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => 0755,
  }

  file { "${home}/.ssh":
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => 0700,
  }

  file { "${home}/.ssh/authorized_keys":
    ensure => present,
    owner  => $user,
    group  => $user,
    mode   => 0644,
  }

  # Read the dirvish key from the puppetmaster
  $pub_key  = ssh_keygen('freight_key','public')

  file_line { 'freight_ssh_public':
    ensure => present,
    path   => "${home}/.ssh/authorized_keys",
    line   => "command=\"${home}/bin/freight_rsync\" ssh-rsa ${pub_key} freight_key\n",
  }

  # Create validation script for rsync connections only
  file { "${home}/bin":
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => 0755,
  }

  file { "${home}/bin/freight_rsync":
    ensure  => present,
    owner   => $user,
    group   => $user,
    mode    => 0755,
    content => template('freight/rsync.erb'),
  }

}
