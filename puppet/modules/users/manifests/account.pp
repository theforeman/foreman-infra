define users::account(
  $fullname,
  $passwd = undef
) {
  user { $name:
    ensure     => present,
    comment    => $fullname,
    home       => "/home/$name",
    managehome => true,
    shell      => '/bin/bash',
    password   => $passwd,
  }

  file { "/home/$name":
    ensure => directory,
    owner  => $name,
    group  => $name,
    mode   => 0755,
  }

  file { "/home/$name/.vimrc":
    source => "puppet:///modules/users/vimrc",
    ensure => present,
    owner => $name,
    group => $name,
    require => File["/home/$name"]
  }

  file { "/home/$name/.ssh":
    ensure  => directory,
    owner   => $name,
    group   => $name,
    mode    => '0700',
    require => [ User["$name"], File["/home/$name"] ]
  }

  file { "/home/$name/.ssh/authorized_keys":
    ensure  => present,
    source  => "puppet:///modules/users/$name-authorized_keys",
    owner   => $name,
    group   => $name,
    mode    => '0600',
    require => File["/home/$name/.ssh"]
  }

  sudo::directive { "sudo-puppet-${name}":
    ensure    => present,
    content   => "$name ALL=(ALL) ALL\n",
  }

}
