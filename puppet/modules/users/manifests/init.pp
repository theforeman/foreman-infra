class users {
  define ssh_user($fullname) {
    user { $name:
      ensure => present,
      comment => $fullname,
      home => "/home/$name",
      managehome => true
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

  file { "/root/.vimrc":
    ensure => present,
    source => "puppet:///modules/users/vimrc",
  }

  ssh_user { "samkottler":
    fullname => "Sam Kottler"
  }

  ssh_user { "gregsutcliffe":
    fullname => "Greg Sutcliffe"
  }

  ssh_user { "ohadlevy":
    fullname => "Ohad Levy"
  }

  ssh_user { "bgupta":
    fullname => "Brian Gupta"
  }
}
