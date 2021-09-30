define web::htpasswd(
  $vhost,
  $passwd = undef,
  $salt = undef,
) {
  $_salt = pick($salt, extlib::cache_data('web_htpasswd_salts', "${vhost}-${name}", extlib::random_password(10)))

  htpasswd { $name:
    ensure      => present,
    target      => "/var/www/vhosts/${vhost}/htpasswd",
    cryptpasswd => htpasswd::ht_crypt($passwd, $_salt),
  }
}
