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
    nagios_host { $name:
      ensure => present,
      address => $name,
      use => "generic-host",
    }

    nagios_service { "${name}_check_ping":
      check_command => "check_ping!100.0,20%!500.0,60%",
      use => "generic-service",
      host_name => $name,
      notification_period => "24x7",
      service_description => "Ping"
    }

    nagios_service { "${name}_check_ssh":
      check_command => "check_ssh",
      use => "generic-service",
      host_name => $name,
      notification_period => "24x7",
      service_description => "SSH"
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
