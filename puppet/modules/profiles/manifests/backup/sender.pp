# @summary The backup sender
#
# @param host
#   The target backup host
# @param username
#   The remote username
class profiles::backup::sender (
  Stdlib::Host $host = 'backups.theforeman.org',
  String[1] $username = "backup-${facts['networking']['hostname']}",
) {
  # There are no packages in EL7 - EL8+ has it in EPEL
  if $facts['os']['family'] == 'RedHat' and versioncmp($facts['os']['release']['major'], '7') <= 0 {
    $params = {
      install_method  => 'url',
      package_version => '0.15.1',
      binary          => '/usr/local/bin/restic',
    }
  } else {
    $params = {}
  }

  class { 'restic':
    backup_timer => 'daily',
    type         => 'sftp',
    host         => $host,
    id           => $username,
    *            => $params,
  }

  $ssh_dir = "${restic::user_homedir}/.ssh"

  file { $ssh_dir:
    ensure => directory,
    owner  => $restic::user,
    group  => $restic::group,
    mode   => '0700',
  }

  file { "${ssh_dir}/id_rsa":
    ensure  => file,
    owner   => $restic::user,
    group   => $restic::group,
    mode    => '0600',
    content => ssh::keygen($username),
  }
}
