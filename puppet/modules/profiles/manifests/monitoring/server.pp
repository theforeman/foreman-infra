class profiles::monitoring::server (
  Stdlib::Host $url = 'monitoring.theforeman.org',
  Boolean $https = true,
) {
  if $https {
    $apache_vhost_custom_params = {
      mdomain => true,
    }
  } else {
    $apache_vhost_custom_params = {}
  }

  class { 'zabbix::database': }
  -> class { 'zabbix::server': }
  -> class { 'zabbix::web':
    zabbix_url                 => $url,
    manage_resources           => true,
    apache_use_ssl             => $https,
    apache_vhost_custom_params => $apache_vhost_custom_params,
  }

  class { 'zabbix::agent':
    server => '127.0.0.1',
  }

  $api_user = getvar('foreman_api_user')
  $api_pass = getvar('foreman_api_password')
  if $api_user and $api_pass {
    $foreman_hosts = foreman::foreman('hosts', '', '20', lookup('foreman_url'), $api_user, $api_pass)
    $foreman_hosts.each |$host| {
      zabbix_host { $host['name']:
        use_ip    => false,
        port      => 10050,
        groups    => ['Linux servers'],
        templates => ['Linux by Zabbix agent'],
      }
    }
  }
}
