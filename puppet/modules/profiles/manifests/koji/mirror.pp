# @summary setup a local mirror of repositories to be used by Koji
#
# @param servername
#   The primary name used for the http vhost
#
# @param serveraliases
#   Any additional names the http server should be responsible for
#
# @param access_require
#   Access restrictions
#
# @param mirror_root
#   Absolute path of the root of the mirror
#
# @param entitlement_id
#   Which entitlement certificate to use when accessing upstream repositories
class profiles::koji::mirror (
  Stdlib::Fqdn $servername = 'mirror.koji.theforeman.org',
  Array[Stdlib::Fqdn] $serveraliases = ['mirror-int.koji.aws.theforeman.org', 'mirror.koji.aws.theforeman.org'],
  Array[String] $access_require = ['ip 127.0.0.1', 'ip 172.16.0.0/12'],
  Stdlib::Absolutepath $mirror_root = '/srv/mirror',
  String $entitlement_id = '3902935856580506602',
) {
  class { 'koji::mirror':
    servername     => $servername,
    serveraliases  => $serveraliases,
    access_require => $access_require,
    mirror_root    => $mirror_root,
    entitlement_id => $entitlement_id,
  }
}
