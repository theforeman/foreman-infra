# AWStats for our webserver
class awstats (
  $vhosts = [
    'all',
    'deb',
    'debugs',
    'downloads',
    'stagingdeb',
    'web',
    'yum',
  ]
) {
  if $facts['os']['name'] == 'CentOS' and $facts['os']['release']['major'] == '8' {
    # https://bugzilla.redhat.com/show_bug.cgi?id=1925801
    # powertools provides perl(Switch)
    yumrepo { 'powertools':
      enabled => '1',
      before  => Package['awstats'],
    }
  }

  package { 'awstats':
    ensure => present,
  }

  # Use a cron per vhost instead of the one shipped in the package
  file { '/etc/cron.hourly/awstats':
    ensure  => absent,
    require => Package['awstats'],
  }

  # Dir for config
  file { '/etc/awstats':
    ensure  => 'directory',
    recurse => true,
    purge   => true,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['awstats'],
  }

  # Dir for output
  file { '/var/www/vhosts/debugs/htdocs/awstats':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  awstats::vhost { $vhosts:
    require => Package['awstats'],
  }
}
