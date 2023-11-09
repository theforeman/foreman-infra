# Basic webserver config
#
# @param letsencrypt
#   Whether to include letsencrypt
class web::base(
  Boolean $letsencrypt = true,
) {
  if $letsencrypt {
    include web::letsencrypt
  }

  include apache

  file { '/var/www/vhosts':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
