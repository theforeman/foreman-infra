class openvox_repo (
  Enum['8', '7'] $release = '8'
) {
  case $facts['os']['family'] {
    'RedHat': {
      include openvox_repo::yum
    }
    'Debian': {
      include openvox_repo::apt
    }
    default: {
      fail("${facts['os']['family']} is unsupported")
    }
  }
  include openvox_repo::purge_puppet
}
