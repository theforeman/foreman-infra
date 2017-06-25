class rbot::config {

  File {
    owner  => $rbot::user,
    group  => $rbot::group,
  }
  group { $rbot::group:
    ensure => 'present',
  }
  user { $rbot::user:
    ensure     => present,
    comment    => 'RBot',
    shell      => '/bin/bash',
    managehome => 'true',
    home       => $rbot::homedir,
  }
  file { "${rbot::homedir}/.rbot":
    ensure => directory,
  }
  file { "${rbot::homedir}/.rbot/plugins":
    ensure => directory,
  }
  file { "${rbot::homedir}/.rbot/conf.yaml.SEED":
    ensure  => file,
    content => template('rbot/conf.yaml.erb'),
  }
  file { '/etc/init.d/rbot':
    ensure  => file,
    mode    => '0755',
    content => template('rbot/rbot-init.erb'),
  }
  file { "${rbot::homedir}/.rbot/plugins/redmine_urls.rb":
    ensure  => present,
    mode    => '0755',
    content => template('rbot/redmine_urls.rb.erb')
  }
  exec { 'seed-rbot-config':
    command => "cp ${rbot::homedir}/.rbot/conf.yaml.SEED ${rbot::homedir}/.rbot/conf.yaml",
    path    => "/bin:/sbin:/usr/bin:/usr/sbin",
    creates => "${rbot::homedir}/.rbot/conf.yaml",
    require => File["${rbot::homedir}/.rbot/conf.yaml.SEED"],
  }
}
