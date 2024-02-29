# @summary A Jenkins node
#
# @param koji_certificate
#   An optional koji certificate for trusted nodes. Only relevant on Red Hat
#   based machines.
#
# @param swap_size_mb
#   The swap file size in MBs. Will be unmanaged if set to 0
#
# @param unittests
#   Should the node be able to run unittests
#
# @param packaging
#   Should the node be able to run packaging jobs
class profiles::jenkins::node (
  Optional[String[1]] $koji_certificate = getvar('koji_cert'),
  Integer[0] $swap_size_mb = 8192,
  Boolean $unittests = $facts['os']['family'] == 'RedHat',
  Boolean $packaging = true,
) {
  class { 'jenkins_node':
    koji_certificate => $koji_certificate,
    unittests        => $unittests,
    packaging        => $packaging,
  }

  if $swap_size_mb > 0 {
    class { 'jenkins_node::swap':
      size_mb => $swap_size_mb,
    }
  }
}
