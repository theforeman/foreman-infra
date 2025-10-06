class openvox_repo::purge_puppet () {
  package {['puppet-release', 'puppet7-release', 'puppet8-release']:
    ensure => absent,
  }
}
