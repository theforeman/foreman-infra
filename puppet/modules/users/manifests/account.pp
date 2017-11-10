define users::account(
  $ensure = 'present',
  $fullname = undef,
  $passwd = undef,
  $homedir = "/home/${title}",
  $sudo = "ALL=(ALL) ALL",
) {
  user { $name:
    ensure     => $ensure,
    comment    => $fullname,
    home       => $homedir,
    managehome => true,
    shell      => '/bin/bash',
    password   => $passwd,
  }

  if $ensure == 'present' {
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
      ensure  => file,
      content => file("${module_name}/${name}-authorized_keys"),
      owner   => $name,
      group   => $name,
      mode    => '0600',
    }
  } elsif $ensure == 'absent' {
    # Allow to revoke users access for cleanup
    file { "${homedir}/.ssh/authorized_keys":
      ensure  => absent,
    }
  }

  sudo::conf { "sudo-puppet-${name}":
    ensure  => $ensure,
    content => "${name} ${sudo}",
  }

}
