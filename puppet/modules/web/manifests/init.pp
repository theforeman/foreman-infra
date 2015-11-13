# $stable::   latest release that users expect
# $latest::   latest release that we have a manual for, change after copying it
# $next::     latest release that we don't have a manual for, before copying it
class web($stable = "1.9", $latest = "1.10", $next = "1.11", $htpasswds = {}) {
  include rsync::server

  secure_ssh::rsync::receiver_setup { 'web':
    user           => 'website',
    foreman_search => 'host = slave01.rackspace.theforeman.org and name = external_ip4',
    script_content => template('web/rsync.erb')
  }

  file { "/etc/httpd/conf.d/welcome.conf":
    ensure => absent
  }

  apache::vhost { "web":
    ensure         => present,
    config_content => template("web/web.conf.erb"),
    user           => 'website',
    group          => 'website',
    mode           => 0755,
  }

  apache::vhost { "debugs":
    ensure         => present,
    config_content => template("web/debugs.conf.erb"),
    user           => 'nobody',
    group          => 'nobody',
    mode           => 0755,
  }

  apache::module { "expires":
    ensure => present,
    notify => Exec["apache-graceful"],
  }
  apache::vhost { "yum":
    ensure      => present,
    config_file => "puppet:///modules/web/yum.theforeman.org.conf",
    mode        => 2575,
  }

  # Auths
  # takes a hash like: { 'user' => { 'vhost' => 'debugs', passwd => 'secret' }
  create_resources(web::htpasswd, $htpasswds)

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
  file { '/var/www/vhosts/yum/htdocs/RPM-GPG-KEY-foreman':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => 0644,
    source => 'puppet:///modules/web/RPM-GPG-KEY-foreman',
  }
  file { "/var/www/vhosts/yum/htdocs/releases":
    ensure => directory,
  }
  file { "/var/www/vhosts/yum/htdocs/releases/latest":
    ensure => link,
    target => $stable,
  }
  file { "/var/www/vhosts/yum/htdocs/releases/nightly":
    ensure => link,
    target => "../nightly",
  }
  file { "/var/www/vhosts/yum/htdocs/plugins/latest":
    ensure => link,
    target => $stable,
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
