class web($latest = "1.2") {
  file { "/etc/httpd/conf.d/welcome.conf":
    ensure => absent
  }

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
    config_file => "puppet:///modules/web/yum.theforeman.org.conf"
  }

  if $osfamily == 'RedHat' {
    package { 'createrepo':
      ensure => present,
    }
  }

  file { "/var/www/vhosts/yum/htdocs/releases/latest":
    ensure => link,
    target => $latest,
  }
}
