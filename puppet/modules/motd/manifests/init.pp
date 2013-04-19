# Class: motd
#
# This module manages 'Message Of The Day'
#
# Parameters:
#   [*ensure*]
#     Ensure if present or absent.
#     Default: present
#
#   [*config_file*]
#     'Message Of The Day' file.
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
#   [*template*]
#     Template to use.
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
# Actions:
#   Manages 'Message Of The Day' content.
#
# Requires:
#   Nothing
#
# Sample Usage:
#   class { 'motd': }
#
# [Remember: No empty lines between comments and class definition]
class motd(
  $ensure = 'present',
  $config_file = $motd::params::config_file,
  $template = $motd::params::template
) inherits motd::params {

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
