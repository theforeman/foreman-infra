# Basic webserver config
class web::base {
  include apache
  include logrotate

  file { '/var/www/vhosts':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
