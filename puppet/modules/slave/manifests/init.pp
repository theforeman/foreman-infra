class slave {
  file { "/var/lib/workspace":
    ensure => directory,
    owner => "jenkins",
    group => "jenkins"
  }
}
