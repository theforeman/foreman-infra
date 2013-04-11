class utility::repos {

  case $::osfamily {
    RedHat: {
      anchor { 'utility::repos::begin': } ->
        class { 'puppetlabs_repo::yum': } ->
      anchor { 'utility::repos::end': }
    }
    Debian: {
      apt::source { 'puppetlabs':
        location   => 'http://apt.puppetlabs.com',
        repos      => 'main',
        key        => '4BD6EC30',
        key_server => 'pgp.mit.edu',
      }
    }
    default: {}
  }
}
