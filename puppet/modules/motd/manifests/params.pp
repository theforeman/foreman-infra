class motd::params {
  case $::osfamily {
    redhat, debian, suse: {
      $config_file = '/etc/motd'
      $template = 'motd/motd.erb'
    }
    default: {
      fail("Unsupported platform: ${::operatingsystem}")
    }
  }
}
