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
class profiles::jenkins::node(
  Optional[String[1]] $koji_certificate = undef,
  Integer[0] $swap_size_mb = 8192,
  Boolean $unittests = true,
  Boolean $packaging = true,
) {
  class { 'slave':
    koji_certificate => $koji_certificate,
    unittests        => $unittests,
    packaging        => $packaging,
  }

  if $swap_size_mb > 0 {
    class { 'slave::swap':
      size_mb => $swap_size_mb,
    }
  }

  # Ensure REX can log in
  class { 'foreman_proxy::plugin::remote_execution::ssh_user':
    manage_user => true,
  }
}
