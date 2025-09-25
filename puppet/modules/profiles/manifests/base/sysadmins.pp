# @summary Ensure root email is delivered
#
# If foreman_users is set via the ENC then that's used. Otherwise it ends up in
# /dev/null.
class profiles::base::sysadmins {
  # Via the Foreman ENC
  if defined('$foreman_users') {
    # lint:ignore:variable_scope
    $sysadmins = $foreman_users.map |$username, $user| { $user['mail'] }
    # lint:endignore
  } else {
    $sysadmins = ['/dev/null']
  }

  mailalias { 'sysadmins':
    ensure    => present,
    recipient => $sysadmins,
  }

  mailalias { 'root':
    ensure    => present,
    recipient => 'sysadmins',
  }
}
