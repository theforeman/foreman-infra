# Define which deploys the key for a specific user
#
# === Parameters:
#
# $name:           name of the key (required)
#
# $user:           user to own the key (required)
#
# $homedir:        home directory the user
#
# $allowed_ips:    list of allowed ips in the authorized keys file
#                  not used if $foreman_search is provided
#
# $foreman_search: string to search in the foreman API, unused by default
#                  if specified, uses the foreman search puppet function to
#                  get IP addresses matching the required string.
#
define secure_ssh::rsync::receiver_setup (
  $user,
  $homedir        = "/home/${user}",
  $foreman_search = false,
  $allowed_ips    = [],
  $script_content = "# Permit transfer\n\$SSH_ORIGINAL_COMMAND\n"
) {
  ::secure_ssh::receiver_setup { $name:
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
