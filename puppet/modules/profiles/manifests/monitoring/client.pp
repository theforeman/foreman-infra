class profiles::monitoring::client (
  Stdlib::Host $server = 'monitoring.theforeman.org',
) {
  class { 'zabbix::agent':
    server => $server,
  }
}
