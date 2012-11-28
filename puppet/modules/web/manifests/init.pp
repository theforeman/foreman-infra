class web {
  apache::vhost { "web":
    ensure => present,
    config_file => "puppet:///modules/web/web.conf"
  }
}
