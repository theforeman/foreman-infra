class nagios::server {
  include nagios::client

  package { "nagios":
    ensure => installed
  }

  service { "nagios":
    enable => true,
    ensure => running,
    require => Package["nagios"]
  }

  Nagios_host <<||>>
  Nagios_service <<||>>
}
