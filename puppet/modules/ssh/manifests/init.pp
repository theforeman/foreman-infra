class ssh {
  file { "/root/.ssh":
    ensure => directory,
    owner  => "root",
    group  => "root"
  }

  file { "/root/.ssh/authorized_keys":
    ensure => file,
    content => $root_ssh_recovery_key,
    require => File["/root/.ssh"]
  }

  case $::osfamily {
    'RedHat': {
      $ssh_service = 'sshd'
    }
    default: {
      $ssh_service = 'ssh'
    }
  }

  file { "/etc/ssh/sshd_config":
    owner   => "root",
    group  => "root",
    ensure => present,
    notify => Service[$ssh_service]
  }

  service { $ssh_service:
    ensure => running,
    enable => true
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
