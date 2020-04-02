class motd::params {
  case $::osfamily {
    'RedHat', 'Debian', 'Suse': {
      $config_file = '/etc/motd'
      $template = 'motd/motd.erb'
    }
    default: {
      fail("Unsupported platform: ${::operatingsystem}")
    }
  }
}
