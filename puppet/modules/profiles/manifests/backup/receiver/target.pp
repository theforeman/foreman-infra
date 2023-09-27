# @summary A backup receiver target
#
# Every server backs up to its own target. This is implemented by creating is
# own user with SSH key. The user is limited to just sftp.
#
# @param username
#   The remote username
# @param ensure
#   The backup receiver target state to ensure.
define profiles::backup::receiver::target (
  String[1] $username = "backup-${title}",
  Enum['present', 'absent'] $ensure = present,
) {
  include profiles::backup::receiver

  $homedir = "${profiles::backup::receiver::directory}/${title}"

  user { $username:
    ensure         => $ensure,
    gid            => $profiles::backup::receiver::group,
    home           => $homedir,
    managehome     => true,
    password       => '!',
    purge_ssh_keys => true,
  }

  # Ensure authorized keys file for proper SELinux labels
  file { "${homedir}/.ssh":
    ensure  => bool2str($ensure == present, 'directory', 'absent'),
    owner   => $username,
    mode    => '0700',
    force   => $ensure == absent,
    seltype => 'ssh_home_t',
  }

  file { "${homedir}/.ssh/authorized_keys":
    ensure  => bool2str($ensure == present, 'file', 'absent'),
    owner   => $username,
    mode    => '0600',
    seltype => 'ssh_home_t',
  }

  ssh_authorized_key { "${username} managed by Puppet":
    ensure => $ensure,
    user   => $username,
    key    => ssh::keygen("backup-${title}", true),
    type   => 'ssh-rsa',
  }
}
