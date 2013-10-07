class utility($sysadmins = ['/dev/null']) {
  include motd

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

  # Figure out how to not conflict with Dirvish
  #package { "rsync":
  #  ensure => present
  #}

  package { "ruby-shadow":
    ensure => installed,
    name => $osfamily ? {
      Debian => "libshadow-ruby1.8",
      default => "ruby-shadow"
    }
  }

  mailalias { 'sysadmins':
    ensure    => present,
    recipient => $sysadmins,
  }
  mailalias { 'root':
    ensure    => present,
    recipient => 'sysadmins',
  }
}
