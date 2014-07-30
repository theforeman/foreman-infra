define web::htpasswd(
  $vhost,
  $passwd = undef
) {
  apache::auth::htpasswd {"${name} in ${vhost}":
    ensure           => present,
    userFileLocation => "/var/www/vhosts/${vhost}",
    userFileName     => "htpasswd",
    username         => $name,
    clearPassword    => $passwd,
  }
}
