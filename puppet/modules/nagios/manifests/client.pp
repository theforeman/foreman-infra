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
    notify => Service["nrpe"],
    require => Package["nrpe"]
  }

  service { "nrpe":
    enable => true,
    ensure => running,
    require => [ Package["nrpe"], Package["nagios-plugins-all"] ]
  }
}
