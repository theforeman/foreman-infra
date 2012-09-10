class users::slave {
  user { "jenkins":
    ensure => present,
    home => "/home/jenkins",
    managehome => true
  }

  file { "/home/jenkins/":
    ensure => directory,
    owner => "jenkins",
    group => "jenkins",
    require => User["jenkins"]
  }

  file { "/home/jenkins/.ssh":
    ensure => directory,
    owner => "jenkins",
    group => "jenkins",
    require => [ User["jenkins"], File["/home/jenkins"] ]
  }

  file { "/home/jenkins/.ssh/authorized_keys":
    ensure => present,
    owner => "jenkins",
    group => "jenkins",
    require => File["/home/jenkins/.ssh"],
    source => "puppet:///modules/users/jenkins-authorized_keys"
  }
}
