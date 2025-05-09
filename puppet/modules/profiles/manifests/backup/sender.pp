# @summary The backup sender
#
# @param host
#   The target backup host
# @param ssh_key
#   The SSH key to use as a known host
# @param ssh_key_type
#   The type of SSH key
# @param username
#   The remote username
class profiles::backup::sender (
  Stdlib::Host $host,
  String[1] $ssh_key,
  String[1] $ssh_key_type,
  String[1] $username,
) {
  require restic

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

  sshkey { $restic::host:
    ensure => present,
    type   => $ssh_key_type,
    key    => $ssh_key,
  }

  User<| title == $restic::user |> { groups +> ['prometheus'] }
}
