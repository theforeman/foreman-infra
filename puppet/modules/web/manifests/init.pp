# $stable::   latest release that users expect
# $latest::   latest release that we have a manual for, change after copying it
# $next::     latest release that we don't have a manual for, before copying it
class web($stable = "1.11", $latest = "1.11", $next = "1.12", $htpasswds = {}) {
  include rsync::server

  if $selinux {
    include selinux

    # Use a non-HTTP specific context to be shared with rsync
    selinux::fcontext { 'fcontext-www':
      context  => 'public_content_t',
      pathname => '/var/www(/.*)?',
    }
  }

  # WWW
  secure_ssh::rsync::receiver_setup { 'web':
    user           => 'website',
    foreman_search => 'host = slave01.rackspace.theforeman.org and (name = external_ip4 or name = external_ip6)',
    script_content => template('web/rsync.erb')
  }
  apache::vhost { "web":
    port            => '80',
    servername      => 'theforeman.org',
    serveraliases   => ['www.theforeman.org'],
    docroot         => '/var/www/vhosts/web/htdocs',
    docroot_owner   => 'website',
    docroot_group   => 'website',
    docroot_mode    => 0755,
    custom_fragment => template("web/web.conf.erb"),
  }

  # DEBUGS
  apache::vhost { "debugs":
    port            => '80',
    servername      => 'debugs.theforeman.org',
    docroot         => '/var/www/vhosts/debugs/htdocs',
    docroot_owner   => 'nobody',
    docroot_group   => 'nobody',
    docroot_mode    => 0755,
    custom_fragment => template("web/debugs.conf.erb"),
  }
  # takes a hash like: { 'user' => { 'vhost' => 'debugs', passwd => 'secret' }
  create_resources(web::htpasswd, $htpasswds)

  # YUM
  apache::vhost { "yum":
    port            => '80',
    servername      => 'yum.theforeman.org',
    docroot         => '/var/www/vhosts/yum/htdocs',
    docroot_mode    => 2575,
    custom_fragment => template('web/yum.conf.erb'),
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

  # DOWNLOADS
  apache::vhost { "downloads":
    port         => '80',
    servername   => 'downloads.theforeman.org',
    docroot      => '/var/www/vhosts/downloads/htdocs',
    docroot_mode => 2575,
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

  # METRICS
  # script to do initial filtering of apache logs for download metrics
  file { '/usr/local/bin/filter_apache_stats':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0744',
    source => 'puppet:///modules/web/filter_apache_stats.sh',
  }

  # daily at 4am, should be fairly quiet on the server
  cron { 'filter_apache_stats':
    command => '/usr/bin/nice -19 /usr/local/bin/filter_apache_stats',
    user    => root,
    hour    => '4',
    minute  => '0'
  }
}
