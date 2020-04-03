# @summary Set up the debugs vhost
# @api private
class web::vhost::debugs(
  Hash[String, Hash] $htpasswds = {},
) {
  web::vhost { 'debugs':
    docroot_owner => 'nobody',
    docroot_group => 'nobody',
    docroot_mode  => '0755',
    attrs         => {
      'custom_fragment' => template('web/debugs.conf.erb'),
    },
  }

  $htpasswds.each |$username, $options| {
    web::htpasswd { $username:
      * => $options,
    }
  }
}
