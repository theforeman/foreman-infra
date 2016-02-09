define web::htpasswd(
  $vhost,
  $passwd = undef
) {
  httpauth { $name:
    ensure   => present,
    file     => "/var/www/vhosts/${vhost}/htpasswd",
    password => $passwd,
  }
}
