class foreman_debug_rsync (
  $base = '/var/www/vhosts/debugs/htdocs',
) {

  class { 'foreman_debug_rsync::config': } ->
  class { 'foreman_debug_rsync::cron': }

}
