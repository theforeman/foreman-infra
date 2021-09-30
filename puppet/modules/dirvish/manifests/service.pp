# @summary Manage the Dirvish service
# @api private
class dirvish::service {
  if $dirvish::use_systemd {
    systemd::timer { 'dirvish.timer':
      timer_content   => template('dirvish/systemd.dirvish.timer.erb'),
      service_content => template('dirvish/systemd.dirvish.service.erb'),
      active          => true,
      enable          => true,
    }
  } else {
    # Dirvish runs from a cronjob
    cron { 'dirvish':
      command => '/etc/dirvish/dirvish-cronjob',
      user    => root,
      hour    => '2',
      minute  => '45',
    }

    if $dirvish::overwrite_cronjob {
      file { '/etc/dirvish/dirvish-cronjob':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => file('dirvish/dirvish-cronjob'),
      }
    }
  }
}
