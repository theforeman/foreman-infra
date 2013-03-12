class utility::repos {

  # This can be expanded to include yum systems later
  case $::operatingsystem {
    fedora,redhat,centos,Scientific: {}
    Debian,Ubuntu: {
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
