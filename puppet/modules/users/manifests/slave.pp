class users::slave {
  include ::sudo

  user { 'jenkins':
    ensure     => present,
    home       => '/home/jenkins',
    managehome => true,
  }

  file { '/home/jenkins':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { '/home/jenkins/.ssh':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { '/home/jenkins/.ssh/authorized_keys':
    ensure => file,
    mode   => '0600',
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/users/jenkins-authorized_keys',
  }

  file { '/home/jenkins/.ssh/config':
    ensure => file,
    mode   => '0600',
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/users/jenkins-ssh_config',
  }

  sudo::conf { 'puppet-jenkins':
    content => 'jenkins ALL=NOPASSWD: ALL',
  }

}
