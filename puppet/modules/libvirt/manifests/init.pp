class libvirt {
  package { "libvirt-dev":
    ensure => present,
    name => $osfamily ? {
      Debian => "libvirt-dev",
      default => "libvirt-devel"
    }
  }
}
