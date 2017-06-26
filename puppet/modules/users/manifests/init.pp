class users (
  $users = 'undef',
) {
  include ::sudo

  file { '/root/.vimrc':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/users/vimrc',
  }

  if $users == 'undef' {
    # Create basic users, delete once foreman is updated
    users::account { 'samkottler':
      fullname => 'Sam Kottler',
    }

    users::account { 'gregsutcliffe':
      fullname => 'Greg Sutcliffe',
    }

    users::account { 'ohadlevy':
      fullname => 'Ohad Levy',
    }

    users::account { 'bgupta':
      fullname => 'Brian Gupta',
    }

    users::account { 'dcleal':
      fullname => 'Dominic Cleal',
    }
  } else {
    # Users hash is passed from Foreman
    create_resources(users::account, $users)
  }

}
