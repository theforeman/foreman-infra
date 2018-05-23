# Class to deploy snapshot management for Scaleway hosts
#
class scaleway(
  Hash[String, Hash] $servers       = {},
  Enum['present', 'absent'] $ensure = present,
) {

  # To hold the API config
  file { '/etc/scaleway':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => 0700,
  }

  file { '/usr/bin/scaleway-snapshot':
    ensure => $ensure,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/scaleway/manage_snapshots.rb',
  }

  # takes a hash like: { 'server' => { 'api_key' => 'abcde', ord_id => '12345' }, ...}
  create_resources(scaleway::cron, $servers)
}
