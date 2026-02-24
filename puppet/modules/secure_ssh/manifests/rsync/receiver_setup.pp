# @summary Define which deploys the key for a specific user
#
# @param user
#   User to own the key
#
# @param script_content
#   Content of a script that'll be run by sshd when the user connects with the
#   key
#
# @param groups
#   Groups the user belongs to
#
# @param homedir
#   Home directory the user
#
# @param homedir_mode
#   Mode of the user's home directory
#
# @param allowed_ips
#   List of allowed ips in the authorized keys file. Unused if $foreman_search
#   is provided
#
# @param foreman_search
#   String to search in the foreman API, unused by default if specified, uses
#   the foreman search puppet function to get IP addresses matching the
#   required string.
#
define secure_ssh::rsync::receiver_setup (
  String $user,
  Enum['present', 'absent'] $ensure = 'present',
  Array[String] $groups = [],
  Stdlib::Absolutepath $homedir = "/home/${user}",
  Stdlib::Filemode $homedir_mode = '0700',
  Optional[String] $foreman_search = undef,
  Array[Stdlib::IP::Address] $allowed_ips = [],
  String $script_content = "# Permit transfer\n\$SSH_ORIGINAL_COMMAND\n",
  Array[String] $authorized_keys = [],
) {
  $directory_ensure = $ensure ? {
    'present' => 'directory',
    'absent'  => 'absent',
  }

  secure_ssh::receiver_setup { $name:
    ensure          => $ensure,
    user            => $user,
    groups          => $groups,
    homedir         => $homedir,
    homedir_mode    => $homedir_mode,
    foreman_search  => $foreman_search,
    allowed_ips     => $allowed_ips,
    ssh_key_name    => "rsync_${name}_key",
    script_content  => template('secure_ssh/script_rsync.erb'),
    authorized_keys => $authorized_keys,
  }

  file { "${homedir}/rsync_cache":
    ensure => $directory_ensure,
    owner  => $user,
  }
}
