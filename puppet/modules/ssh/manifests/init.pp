class ssh {
  file { "/root/.ssh":
    ensure => directory
  }

  file { "/root/.ssh/authorized_keys":
    ensure => file,
    content => $root_ssh_recovery_key,
    require => File["/root/.ssh"]
  }

  case $::osfamily {
    RedHat: {
      $ssh_service = 'sshd'
    }
    default: {
      $ssh_service = 'ssh'
    }
  }

  file { "/etc/ssh/sshd_config":
    ensure => present,
    source => "puppet:///modules/ssh/sshd_config",
    notify => Service[$ssh_service]
  }

  service { $ssh_service:
    ensure => running,
    enable => true
  }
}
