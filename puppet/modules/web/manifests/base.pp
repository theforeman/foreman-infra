class web::base(
  Boolean $letsencrypt = true,
) {
  if $letsencrypt {
    include ::web::letsencrypt
  }

  class { '::apache':
    default_vhost => false,
  }

  file { '/var/www/vhosts':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
