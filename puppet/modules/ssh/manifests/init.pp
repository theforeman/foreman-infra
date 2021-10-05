class ssh {
  $ssh_service = $facts['os']['family'] ? {
    'RedHat' => 'sshd',
    default  => 'ssh',
  }

  file { '/etc/ssh/sshd_config':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    notify => Service[$ssh_service],
  }

  service { $ssh_service:
    ensure => running,
    enable => true,
  }

  Sshd_config <| |> ~> Service[$ssh_service]

  sshd_config { 'PermitRootLogin':
    ensure => present,
    value  => 'without-password',
  }

  sshd_config { 'PasswordAuthentication':
    ensure => present,
    value  => 'no',
  }

  sshd_config { 'StrictModes':
    ensure => present,
    value  => 'yes',
  }

  # Log SSH key fingerprints
  sshd_config { 'LogLevel':
    ensure => present,
    value  => 'VERBOSE',
  }
}
