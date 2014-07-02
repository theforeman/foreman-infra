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
define secure_rsync::uploader_key (
  $user,
  $dir        = "/home/$user/.ssh",
  $mode       = 0600,
  $manage_dir = false,
) {

  $pub_key  = ssh_keygen({name => "rsync_${name}_key", public => 'public'})
  $priv_key = ssh_keygen({name => "rsync_${name}_key"})

  if $manage_dir {
    file { $dir:
      ensure => directory,
      owner  => $user,
      mode   => $mode,
    }
  }

  file { "${dir}/rsync_${name}_key":
    owner   => $user,
    mode    => 0400,
    content => "${priv_key}",
  }

  file { "${dir}/rsync_${name}_key.pub":
    owner   => $user,
    mode    => 0644,
    content => "ssh-rsa ${pub_key} rsync_${name}_key from puppetmaster\n",
  }
}
