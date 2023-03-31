# @summary A backup receiver target
#
# Every server backs up to its own target. This is implemented by creating is
# own user with SSH key. The user is limited to just sftp.
#
# @param username
#   The remote username
define profiles::backup::receiver::target (
  String[1] $username = "backup-${title}",
) {
  include profiles::backup::receiver

  $homedir = "${profiles::backup::receiver::directory}/${title}"

  user { $username:
    ensure         => present,
    gid            => $profiles::backup::receiver::group,
    home           => $homedir,
    managehome     => true,
    password       => '!',
    purge_ssh_keys => true,
  }

  # Ensure authorized keys file for proper SELinux labels
  file { "${homedir}/.ssh":
    ensure  => directory,
    owner   => $username,
    mode    => '0700',
    seltype => 'ssh_home_t',
  }

  file { "${homedir}/.ssh/authorized_keys":
    ensure  => file,
    owner   => $username,
    mode    => '0600',
    seltype => 'ssh_home_t',
  }

  ssh_authorized_key { "${username} managed by Puppet":
    user => $username,
    key  => ssh::keygen("backup-${title}", true),
    type => 'ssh-rsa',
  }
}
