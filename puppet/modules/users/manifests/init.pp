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
