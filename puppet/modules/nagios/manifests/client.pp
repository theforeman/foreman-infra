class nagios::client {
  package { "nrpe":
    ensure => installed
  }

  package { "nagios-plugins-all":
    ensure => installed
  }

  file { "/etc/nagios/nrpe.cfg":
    ensure => present,
    content => template("nagios/nrpe.cfg.erb"),
    notify => Service["nrpe"]
  }

  service { "nrpe":
    enable => true,
    ensure => running,
    require => [ Package["nrpe"], Package["nagios-plugins-all"] ]
  }

  @@nagios_host { $fqdn:
    ensure => present,
    alias => $hostname,
    address => $ipaddress,
    use => "generic-host",
  }

  @@nagios_service { "check_ping_${hostname}":
    check_command => "check_ping!100.0,20%!500.0,60%",
    host_name => "$hostname",
  }
}
