class utility {
  package { "vim":
    ensure => present,
    name => $osfamily ? {
      Redhat => "vim-enhanced",
      default => "vim"
    }
  }

  package { "htop":
    ensure => present
  }

  package { "iftop":
    ensure => present
  }

  package { "screen":
    ensure => present
  }

  package { "rsync":
    ensure => present
  }
}
