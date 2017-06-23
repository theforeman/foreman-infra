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
define secure_ssh::uploader_key (
  $user,
  $dir          = "/home/${user}/.ssh",
  $mode         = '0600',
  $manage_dir   = false,
  $ssh_key_name = "${name}_key",
) {

  $pub_key  = ssh_keygen({name => $ssh_key_name, public => 'public'})
  $priv_key = ssh_keygen({name => $ssh_key_name})

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
