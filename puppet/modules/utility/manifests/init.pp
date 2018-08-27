class utility($sysadmins = ['/dev/null']) {
  include motd
  include unattended

  package { 'vim':
    ensure => present,
    name => $osfamily ? {
      'RedHat' => 'vim-enhanced',
      default  => 'vim'
    }
  }

  package { 'htop':
    ensure => present
  }

  package { 'iftop':
    ensure => present
  }

  package { 'screen':
    ensure => present
  }

  # Figure out how to not conflict with Dirvish
  #package { 'rsync':
  #  ensure => present
  #}

  package { 'ruby-shadow':
    ensure => installed,
    name   => 'ruby-shadow',
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
