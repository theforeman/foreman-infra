class users {
  file { "/root/.vimrc":
    ensure => present,
    source => "puppet:///modules/users/vimrc",
  }

  users::account { "samkottler":
    fullname => "Sam Kottler"
  }

  users::account { "gregsutcliffe":
    fullname => "Greg Sutcliffe"
  }

  users::account { "ohadlevy":
    fullname => "Ohad Levy"
  }

  users::account { "bgupta":
    fullname => "Brian Gupta"
  }

  users::account { "dcleal":
    fullname => "Dominic Cleal"
  }
}
