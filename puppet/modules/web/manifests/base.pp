class web::base {
  include ::web::letsencrypt

  class { '::apache':
    default_vhost => false,
  }
}
