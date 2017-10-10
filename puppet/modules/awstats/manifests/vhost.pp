define awstats::vhost {

  file { "/etc/awstats/awstats.${name}.conf":
    ensure => present,
    mode => '0644',
    owner => 'root',
    group => 'root',
    content => template('awstats/awstats.conf.erb'),
  }

  file { "/var/lib/awstats/${name}":
    ensure => directory,
    mode => '0755',
    owner => 'root',
    group => 'root',
  }

  file { "/etc/cron.hourly/awstats-${name}":
    ensure => present,
    mode => '0755',
    owner => 'root',
    group => 'root',
    content => template('awstats/cron.erb')
  }

  file { "/var/www/vhosts/debugs/htdocs/awstats/${name}.html":
    ensure => present,
    mode => '0644',
    owner => 'root',
    group => 'root',
  }
}
