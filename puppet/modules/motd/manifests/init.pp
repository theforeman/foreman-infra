# @summary This module manages 'Message Of The Day'
#
# @param ensure
#   Ensure if present or absent.
#
# @param config_file
#   'Message Of The Day' file.
#
# @param template
#   Template to use. Only set this, if your platform is not supported or you
#   know, what you're doing.
#
# @example
#   class { 'motd': }
#
class motd(
  Enum['present', 'absent'] $ensure = 'present',
  Stdlib::Absolutepath $config_file = '/etc/motd',
  String[1] $template = 'motd/motd.erb',
) {

  if $ensure == 'present' {
    $ensure_real = 'file'
  } else {
    $ensure_real = 'absent'
  }

  file { $config_file:
    ensure  => $ensure_real,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($template),
  }
}
