# Basic webserver config
class web::base {
  include apache

  file { '/var/www/vhosts':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
