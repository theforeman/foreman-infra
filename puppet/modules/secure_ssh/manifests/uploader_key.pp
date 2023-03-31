# Define which deploys the key for a specific user
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
# @param ssh_key_name
#   The name of the key
#
define secure_ssh::uploader_key (
  String[1] $user,
  Stdlib::Absolutepath $dir = "/home/${user}/.ssh",
  Stdlib::Filemode $mode = '0600',
  Boolean $manage_dir = false,
  String[1] $ssh_key_name = "${name}_key",
) {
  $pub_key  = ssh::keygen($ssh_key_name, true)
  $priv_key = ssh::keygen($ssh_key_name)

  if $manage_dir {
    file { $dir:
      ensure => directory,
      owner  => $user,
      mode   => $mode,
    }
  }

  file { "${dir}/${ssh_key_name}":
    owner   => $user,
    mode    => '0400',
    content => $priv_key,
  }

  file { "${dir}/${ssh_key_name}.pub":
    owner   => $user,
    mode    => '0644',
    content => "ssh-rsa ${pub_key} ${ssh_key_name} from puppetmaster\n",
  }
}
