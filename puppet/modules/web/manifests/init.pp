# @summary the webserver configuration
#
# All vhosts can be protected by a single SSL cert with additional names added
# in the certonly $domains parameter below.
#
# @param https
#   to request an LE cert via webroot mode, the HTTP vhost must be up.  To
#   start httpd, the certs have to exist, so keep SSL vhosts disabled until the
#   certs are present via the HTTP vhost and only then enable the SSL vhosts.
#
class web(
  Boolean $https = false,
) {
  class { 'web::base':
    letsencrypt => $https,
  }

  if $https {
    $letsencypt_domain = 'theforeman.org'

    letsencrypt::certonly { $letsencypt_domain:
      plugin        => 'webroot',
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
  }

  if $facts['os']['selinux']['enabled'] {
    include selinux

    # Use a non-HTTP specific context to be shared with rsync
    selinux::fcontext { 'fcontext-www':
      seltype  => 'public_content_t',
      pathspec => '/var/www(/.*)?',
    }
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

  file { '/usr/local/bin/fastly-purge':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file('web/fastly-purge.sh'),
  }

  file { '/usr/local/bin/fastly-purge-find':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file('web/fastly-purge-find.sh'),
  }

  # daily at 4am, should be fairly quiet on the server
  cron { 'filter_apache_stats':
    command => '/usr/bin/nice -19 /usr/local/bin/filter_apache_stats',
    user    => root,
    hour    => '4',
    minute  => '0',
  }
}
