define users::account (
  Enum['present', 'absent'] $ensure = 'present',
  Optional[String] $fullname = undef,
  Optional[String] $passwd = undef,
  Stdlib::Absolutepath $homedir = "/home/${title}",
  Boolean $sudo = true,
) {
  if $sudo {
    include sudo
    $groups = [if $facts['os']['family'] == 'Debian' { 'sudo' } else { 'wheel' }]
  } else {
    $groups = []
  }

  user { $name:
    ensure     => $ensure,
    comment    => $fullname,
    home       => $homedir,
    groups     => $groups,
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
  }
}
