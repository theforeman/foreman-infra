class dirvish::service {

  if $::dirvish::use_systemd {
    file { '/etc/systemd/system/dirvish.timer':
      content => template('dirvish/systemd.dirvish.timer.erb'),
      notify  => Exec['dirvish-systemctl-daemon-reload'],
    }

    file { '/etc/systemd/system/dirvish.service':
      content => template('dirvish/systemd.dirvish.service.erb'),
      notify  => Exec['dirvish-systemctl-daemon-reload'],
    }

    exec { 'dirvish-systemctl-daemon-reload':
      refreshonly => true,
      path        => $::path,
      command     => 'systemctl daemon-reload',
      subscribe   => [
        File['/etc/systemd/system/dirvish.service'],
        File['/etc/systemd/system/dirvish.timer'],
      ],
    }

    service { 'dirvish.timer':
      provider  => 'systemd',
      ensure    => running,
      enable    => true,
      subscribe => [
        File['/etc/systemd/system/dirvish.timer'],
        File['/etc/systemd/system/dirvish.service'],
        Exec['dirvish-systemctl-daemon-reload'],
      ],
    }
  } else {
    # Dirvish runs from a cronjob
    cron { 'dirvish':
      command => '/etc/dirvish/dirvish-cronjob',
      user    => root,
      hour    => '2',
      minute  => '45'
    }

    if $::dirvish::overwrite_cronjob {
      file { '/etc/dirvish/dirvish-cronjob':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/dirvish/dirvish-cronjob',
      }
    }
  }
}
