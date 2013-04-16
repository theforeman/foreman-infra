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

  define monitored_slave {
    $address = $name

    nagios_host { $address:
      ensure => present,
      address => $address,
      use => "generic-host",
    }

    nagios_service { "$address_check_ping":
      check_command => "check_ping!100.0,20%!500.0,60%",
      use => "generic-service",
      host_name => $address,
      notification_period => "24x7",
      service_description => "Check Ping"
    }
  }

  $builders = [
    "5.9.188.105",
    "5.9.167.119",
    "5.9.167.120",
    "5.9.167.122"
  ]

  monitored_slave { $builders: }
}
