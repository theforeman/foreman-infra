class web::letsencrypt(
  $email = 'foreman-infra-notifications@googlegroups.com',
) {
  class { '::letsencrypt':
    email          => $email,
    configure_epel => false,
  }

  cron { 'letsencrypt_renew':
    command => "${::letsencrypt::command} renew --quiet --renew-hook '/bin/systemctl reload httpd'",
    user    => 'root',
    weekday => '6',
    hour    => '3',
    minute  => '27',
  }
}
