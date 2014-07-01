class web($latest = "1.5") {
  include rsync::server
  include web::website_user

  file { "/etc/httpd/conf.d/welcome.conf":
    ensure => absent
  }

  apache::vhost { "web":
    ensure         => present,
    config_content => template("web/web.conf.erb"),
    owner          => 'website',
    group          => 'website',
    mode           => 0755,
  }

  apache::vhost { "yum":
    ensure      => present,
    config_file => "puppet:///modules/web/yum.theforeman.org.conf",
    mode        => 2575,
  }
  rsync::server::module { 'yum':
    path      => '/var/www/vhosts/yum/htdocs',
    list      => true,
    read_only => true,
    comment   => 'yum.theforeman.org',
    uid       => 'nobody',
    gid       => 'nobody',
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

  apache::vhost { "downloads":
    ensure      => present,
    config_file => "puppet:///modules/web/downloads.theforeman.org.conf",
    mode        => 2575,
  }
  rsync::server::module { 'downloads':
    path      => '/var/www/vhosts/downloads/htdocs',
    list      => true,
    read_only => true,
    comment   => 'downloads.theforeman.org',
    uid       => 'nobody',
    gid       => 'nobody',
  }
  file { '/var/www/vhosts/downloads/htdocs/HEADER.html':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => 0644,
    source => 'puppet:///modules/web/downloads-HEADER.html',
  }
}
