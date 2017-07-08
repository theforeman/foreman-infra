class rbot::params {
  $base_dir    = '/opt'
  $version     = '0.9.15'
  $working_dir = "${base_dir}/rbot-${version}"
  $user        = 'rbot'
  $group       = 'rbot'
  $homedir     = "/home/${user}"

  # RBot Defaults
  $auth_password   = 'rbotauth'
  $reply_with_nick = false
  $address_prefix  = '!'
  $nick_postfix    = ':'
  $core_language   = 'english'
  $ssl             = false
  $plugin_dir      = ['(default)', '(default)/games', '(default)/contrib']
}
