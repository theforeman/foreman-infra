# Define which deploys the key for a specific user
#
# @param user
#   User to own the key
#
# @param script_content
#   Content of a script that'll be run by sshd when the user connects with the
#   key
#
# @param homedir
#   Home directory the user
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
  Stdlib::Absolutepath $homedir = "/home/${user}",
  Optional[String] $foreman_search = undef,
  Array[Stdlib::IP::Address] $allowed_ips = [],
  String $script_content = "# Permit transfer\n\$SSH_ORIGINAL_COMMAND\n",
) {
  secure_ssh::receiver_setup { $name:
    user           => $user,
    homedir        => $homedir,
    foreman_search => $foreman_search,
    allowed_ips    => $allowed_ips,
    ssh_key_name   => "rsync_${name}_key",
    script_content => template('secure_ssh/script_rsync.erb'),
  }

  file { "${homedir}/rsync_cache":
    ensure => directory,
    owner  => $user,
  }
}
