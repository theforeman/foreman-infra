class users::slave {
  include sudo

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
    ensure  => present,
    mode    => '0600',
    owner   => "jenkins",
    group   => "jenkins",
    require => File["/home/jenkins/.ssh"],
    source  => "puppet:///modules/users/jenkins-authorized_keys"
  }

  file { "/home/jenkins/.ssh/config":
    ensure  => present,
    mode    => '0600',
    owner   => "jenkins",
    group   => "jenkins",
    require => File["/home/jenkins/.ssh"],
    source  => "puppet:///modules/users/jenkins-ssh_config"
  }

  sudo::directive { "puppet-jenkins":
    ensure => present,
    content => "jenkins ALL=NOPASSWD: ALL\n"
  }

}
