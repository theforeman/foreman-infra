class users::slave {
  include ::sudo

  users::account { 'jenkins':
    sudo => 'ALL=NOPASSWD: ALL',
  }

  file { '/home/jenkins/.ssh/config':
    ensure  => file,
    mode    => '0600',
    owner   => 'jenkins',
    group   => 'jenkins',
    content => "StrictHostKeyChecking no\n",
  }
}
