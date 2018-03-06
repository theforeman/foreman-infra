# Various basic utilities
class utility($sysadmins = ['/dev/null']) {
  include motd
  include unattended

  $vim = $::osfamily ? {
    'RedHat' => 'vim-enhanced',
    default  => 'vim',
  }

  ensure_packages([$vim, 'htop', 'iftop', 'screen', 'rsync', 'ruby-shadow'])

  mailalias { 'sysadmins':
    ensure    => present,
    recipient => $sysadmins,
  }
  mailalias { 'root':
    ensure    => present,
    recipient => 'sysadmins',
  }
}
