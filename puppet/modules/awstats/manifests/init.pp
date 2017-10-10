class awstats (
  $vhosts = [
    'all',
    'deb',
    'debugs',
    'downloads',
    'stagingdeb',
    'web',
    'yum'
  ]
) {

  package { 'awstats': ensure => present }

  # Use a cron per vhost instead of the one shipped in the package
  file { '/etc/cron.hourly/awstats': ensure => absent }

  # Dir for config
  file { '/etc/awstats': 
    ensure => 'directory',
    recurse => true,
    purge  => true,
    mode => '0755',
    owner => 'root',
    group => 'root',
  }

  # Dir for output
  file { '/var/www/vhosts/debugs/htdocs/awstats':
    ensure => 'directory',
    mode => '0755',
    owner => 'root',
    group => 'root',
  }

  awstats::vhost { $vhosts: }

}
