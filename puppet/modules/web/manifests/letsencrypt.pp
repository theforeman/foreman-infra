class web::letsencrypt(
  $email = 'foreman-infra-notifications@googlegroups.com',
) {
  class { '::letsencrypt':
    email          => $email,
    configure_epel => false,
  }

  cron { 'letsencrypt_renew':
    command => '/usr/bin/certbot renew --renew-hook "/sbin/service httpd reload"',
    user    => 'root',
    weekday => '6',
    hour    => '3',
    minute  => '27',
  }
}
