define users::account(
  $fullname,
  $passwd = undef,
  $homedir = "/home/${title}",
) {
  user { $name:
    ensure     => present,
    comment    => $fullname,
    home       => $homedir,
    managehome => true,
    shell      => '/bin/bash',
    password   => $passwd,
  }

  file { $homedir:
    ensure => directory,
    owner  => $name,
    group  => $name,
    mode   => '0755',
  }

  file { "${homedir}/.ssh":
    ensure => directory,
    owner  => $name,
    group  => $name,
    mode   => '0700',
  }

  file { "${homedir}/.ssh/authorized_keys":
    ensure => file,
    source => "puppet:///modules/users/${name}-authorized_keys",
    owner  => $name,
    group  => $name,
    mode   => '0600',
  }

  sudo::conf { "sudo-puppet-${name}":
    content => "${name} ALL=(ALL) ALL",
  }

}
