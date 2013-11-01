class web($latest = "1.3") {
  include rsync::server

  file { "/etc/httpd/conf.d/welcome.conf":
    ensure => absent
  }

  file { "/var/www/vhosts/web_theforeman.org":
    ensure => link,
    target => "/var/www/cap/theforeman.org/current/_site/",
  }

  apache::vhost { "web":
    ensure         => present,
    config_content => template("web/web.conf.erb"),
    require        => File["/var/www/vhosts/web_theforeman.org"],
  }

  apache::vhost { "yum":
    ensure => present,
    config_file => "puppet:///modules/web/yum.theforeman.org.conf"
  }
  rsync::server::module { 'yum':
    path      => '/var/www/vhosts/yum/htdocs',
    list      => true,
    read_only => true,
    comment   => 'yum.theforeman.org',
  }

  if $osfamily == 'RedHat' {
    package { 'createrepo':
      ensure => present,
    }
  }

  file { '/var/www/vhosts/yum/htdocs/HEADER.html':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => 0644,
    source => 'puppet:///modules/web/yum-HEADER.html',
  }
  file { "/var/www/vhosts/yum/htdocs/releases":
    ensure => directory,
  }
  file { "/var/www/vhosts/yum/htdocs/releases/latest":
    ensure => link,
    target => $latest,
  }
  file { "/var/www/vhosts/yum/htdocs/plugins/latest":
    ensure => link,
    target => $latest,
  }
}
