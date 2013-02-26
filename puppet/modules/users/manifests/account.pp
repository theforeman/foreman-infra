define users::account($fullname) {
  user { $name:
    ensure     => present,
    comment    => $fullname,
    home       => "/home/$name",
    managehome => true
    shell      => '/bin/bash',
  }

  file { "/home/$name":
    ensure => directory
  }

  file { "/home/$name/.vimrc":
    source => "puppet:///modules/users/vimrc",
    ensure => present,
    owner => $name,
    group => $name,
    require => File["/home/$name"]
  }
   
  file { "/home/$name/.ssh":
    ensure => directory,
    owner => $name,
    group => $name,
    require => [ User["$name"], File["/home/$name"] ]
  }

  file { "/home/$name/.ssh/authorized_keys":
    ensure => present,
    source => "puppet:///modules/users/$name-authorized_keys",
    owner => $name,
    group => $name,
    require => File["/home/$name/.ssh"]
  }
}
