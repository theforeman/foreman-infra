# @summary Manage the debug rsync setup
#
# Users can upload their debugs using foreman-debug.
# This sets up the receiver part of that.
#
# @param base
#   The base directory where rsync data is stored
class foreman_debug_rsync (
  Stdlib::Absolutepath $base = '/var/www/vhosts/debugs/htdocs',
) {
  contain foreman_debug_rsync::config
  contain foreman_debug_rsync::cron

  Class['foreman_debug_rsync::config'] -> Class['foreman_debug_rsync::cron']
}
