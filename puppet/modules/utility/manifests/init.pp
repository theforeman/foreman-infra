class utility {
  package { "vim":
    ensure => present,
    name => $osfamily ? {
      Redhat => "vim-enhanced",
      Debian => "vim"
    }
  }

  package { "htop":
    ensure => present
  }
}
