# @summary The backup receiver
#
# The receiver sets up a group and a directory where all backup targets can
# live.
#
# @see profiles::backup::receiver::target
#
# @param targets
#   The various targets to ensure
# @param group
#   The group which all targets belong to
# @param directory
#   The parent directory for all targets
# @param ensure
#   The backup receiver state to ensure.
class profiles::backup::receiver (
  Array[String[1]] $targets = [],
  String[1] $group = 'backup',
  Stdlib::Absolutepath $directory = '/srv/backup',
  Enum['present', 'absent'] $ensure = present,
) {
  group { $group:
    ensure => $ensure,
  }

  if $ensure == present {
    file { $directory:
      ensure => 'directory',
      owner  => 'root',
      group  => $group,
      mode   => '0750',
    }
  }

  # Ensure $directory/.ssh is set to to ssh_home_t
  if $facts['os']['selinux']['enabled'] and $directory != '/home' {
    selinux::fcontext { 'backup-ssh':
      ensure   => $ensure,
      seltype  => 'ssh_home_t',
      pathspec => "${directory}/[^/]+/\\.ssh(/.*)?",
    }
  }

  include ssh

  $sshd_match = "Group ${group}"
  sshd_config_match { $sshd_match:
    ensure => $ensure,
  }

  # TODO: ChrootDirectory %h

  sshd_config { 'DisableForwarding':
    ensure    => $ensure,
    condition => $sshd_match,
    value     => 'yes',
  }

  sshd_config { 'ForceCommand':
    ensure    => $ensure,
    condition => $sshd_match,
    value     => 'internal-sftp',
  }

  $require = Sshd_config['DisableForwarding', 'ForceCommand']

  $targets.each |$target| {
    profiles::backup::receiver::target { $target:
      ensure  => $ensure,
      require => $require,
    }
  }
}
