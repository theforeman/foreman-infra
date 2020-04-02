# The Foreman rbot instance
class rbot(
  $servers,
  $nickname,
  $channels,
  $base_dir        = $rbot::params::base_dir,
  $version         = $rbot::params::version,
  $working_dir     = $rbot::params::working_dir,
  $user            = $rbot::params::user,
  $group           = $rbot::params::group,
  $homedir         = $rbot::params::homedir,
  $auth_password   = $rbot::params::auth_password,
  $reply_with_nick = $rbot::params::reply_with_nick,
  $address_prefix  = $rbot::params::address_prefix,
  $nick_postfix    = $rbot::params::nick_postfix,
  $core_language   = $rbot::params::core_language,
  $ssl             = $rbot::params::ssl,
  $plugin_dir      = $rbot::params::plugin_dir,
  $irc_password    = undef,
  $bind_host       = undef,
) inherits rbot::params {
  anchor { 'rbot::begin': } ->
  class  { 'rbot::package': } ~>
  class  { 'rbot::config': } ~>
  class  { 'rbot::service': } ->
  anchor { 'rbot::end': }
}
