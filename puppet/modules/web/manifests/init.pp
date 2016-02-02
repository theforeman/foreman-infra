# $stable::   latest release that users expect
# $latest::   latest release that we have a manual for, change after copying it
# $next::     latest release that we don't have a manual for, before copying it
#
# All vhosts can be protected by a single SSL cert with additional names added in the certonly
# $domains parameter below.
#
# $https:: to request an LE cert via webroot mode, the HTTP vhost must be up.  To start httpd, the
#          certs have to exist, so keep SSL vhosts disabled until the certs are present via the HTTP
#          vhost and only then enable the SSL vhosts.
class web($stable = "1.11", $latest = "1.12", $next = "1.13", $htpasswds = {}, $https = false) {
  include apache
  include rsync::server

  class { 'letsencrypt':
    email => 'foreman-infra-notifications@googlegroups.com'
  }

  letsencrypt::certonly { 'theforeman.org':
    plugin        => 'webroot',
    manage_cron   => false,
    # domain / webroot_paths must match exactly
    domains       => [
      'theforeman.org',
      'deb.theforeman.org',
      'debugs.theforeman.org',
      'downloads.theforeman.org',
      'stagingdeb.theforeman.org',
      'www.theforeman.org',
      'yum.theforeman.org',
    ],
    webroot_paths => [
      '/var/www/vhosts/web/htdocs',
      '/var/www/vhosts/deb/htdocs',
      '/var/www/vhosts/debugs/htdocs',
      '/var/www/vhosts/downloads/htdocs',
      '/var/www/vhosts/stagingdeb/htdocs',
      '/var/www/vhosts/web/htdocs',
      '/var/www/vhosts/yum/htdocs',
    ],
  }

  cron { 'letsencrypt_renew':
    command => '/usr/bin/certbot renew --renew-hook "/sbin/service httpd reload"',
    user    => root,
    weekday => '6',
    hour    => '3',
    minute  => '27'
  }

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
  $web_attrs = {
    servername      => 'theforeman.org',
    serveraliases   => ['www.theforeman.org'],
    docroot         => '/var/www/vhosts/web/htdocs',
    docroot_owner   => 'website',
    docroot_group   => 'website',
    docroot_mode    => 0755,
    custom_fragment => template("web/web.conf.erb"),
  }

  # DEBUGS
  $debugs_attrs = {
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
  $yum_attrs = {
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
  $downloads_attrs = {
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

  # Create the vhosts defined above
  create_resources(
    'apache::vhost',
    {
      'debugs'    => $debugs_attrs,
      'downloads' => $downloads_attrs,
      'web'       => $web_attrs,
      'yum'       => $yum_attrs,
    },
    {
      'port' => '80',
    }
  )

  if $https {
    create_resources(
      'apache::vhost',
      {
        'debugs-https'    => $debugs_attrs,
        'downloads-https' => $downloads_attrs,
        'web-https'       => $web_attrs,
        'yum-https'       => $yum_attrs,
      },
      {
        'port'      => '443',
        'ssl'       => true,
        'ssl_cert'  => '/etc/letsencrypt/live/theforeman.org/fullchain.pem',
        'ssl_chain' => '/etc/letsencrypt/live/theforeman.org/chain.pem',
        'ssl_key'   => '/etc/letsencrypt/live/theforeman.org/privkey.pem',
        'require'   => Letsencrypt::Certonly['theforeman.org'],
      }
    )
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
