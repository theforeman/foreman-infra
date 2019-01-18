class users::slave {
  include ::sudo

  # On Debian we use pbuilder with sudo
  $sudo = $facts['osfamily'] ? {
    'Debian' => 'ALL=NOPASSWD: ALL',
    default  => '',
  }

  users::account { 'jenkins':
    sudo => $sudo,
  }

  file { '/home/jenkins/.ssh/config':
    ensure  => file,
    mode    => '0600',
    owner   => 'jenkins',
    group   => 'jenkins',
    content => "StrictHostKeyChecking no\n",
  }
}
