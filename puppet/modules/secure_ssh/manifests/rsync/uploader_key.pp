# Define which deploys the key for a specific user
#
# === Parameters:
#
# $name:       name of the key (required)
#
# $user:       user to own the key (required)
#
# $dir:        directory to store the key in (default: /home/$user/.ssh)
#
# $mode:       mode of $dir (default: 0600)
#
# $manage_dir  whether or not to manage $dir (default: false)
#              type: boolean
#
define secure_ssh::rsync::uploader_key (
  $user,
  $dir          = "/home/${user}/.ssh",
  $mode         = 0600,
  $manage_dir   = false,
) {
  ::secure_ssh::uploader_key { $name:
    user         => $user,
    dir          => $dir,
    mode         => $mode,
    manage_dir   => $manage_dir,
    ssh_key_name => "rsync_${name}_key",
  }
}
