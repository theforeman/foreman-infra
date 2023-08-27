# @summary Define which deploys the key for a specific user
#
# @param name
#   Name of the key
#
# @param user
#   User to own the key
#
# @param dir
#   Directory to store the key in
#
# @param mode
#   Mode of $dir
#
# @param manage_dir
#   Whether or not to manage $dir
#
define secure_ssh::rsync::uploader_key (
  String[1] $user,
  Stdlib::Absolutepath $dir = "/home/${user}/.ssh",
  Stdlib::Filemode $mode = '0600',
  Boolean $manage_dir = false,
  String[1] $ensure = 'present',
) {
  secure_ssh::uploader_key { $name:
    ensure       => $ensure,
    user         => $user,
    dir          => $dir,
    mode         => $mode,
    manage_dir   => $manage_dir,
    ssh_key_name => "rsync_${name}_key",
  }
}
