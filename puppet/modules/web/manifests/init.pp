class web {
  file { "/var/www/vhosts/web_theforeman.org":
    ensure => link,
    target => "/var/www/cap/theforeman.org/current/_site/",
  }

  apache::vhost { "web":
    ensure      => present,
    config_file => "puppet:///modules/web/web.conf",
    require     => File["/var/www/vhosts/web_theforeman.org"],
  }

  apache::vhost { "deb":
    ensure      => present,
    config_file => "puppet:///modules/web/deb.theforeman.org.conf",
    require     => File["/srv/freight/web"],
  }

  apache::vhost { "yum":
    ensure => present,
    config_file => "puppet://modules/web/yum.theforeman.org.conf",
    require => File["/var/www/vhosts/yum/htdocs"]
  }
}
