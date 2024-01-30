# @summary Install rbenv
#
# This module is based on jdowning/rbenv but uses system packages instead of git checkouts.
#
# @param install_dir
#   The path where rbenv builds will be installed to
#
# @param env
#   Default Environment variables to use when installing a build
class rbenv (
  Stdlib::Absolutepath $install_dir = '/usr/local/rbenv',
  Array[String[1]] $env = [],
) {
  $packages = $facts['os']['family'] ? {
    'RedHat' => ['rbenv', 'ruby-build-rbenv'],
    'Debian' => ['rbenv', 'ruby-build'], # ruby-build contains the rbenv plugin
    undef    => [],
  }

  class { 'rbenv::install':
    packages => $packages,
  }

  contain rbenv::install
}
