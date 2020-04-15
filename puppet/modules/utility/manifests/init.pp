# Various basic utilities
class utility($sysadmins = ['/dev/null']) {
  include motd
  include unattended

  $vim = $facts['os']['family'] ? {
    'RedHat' => 'vim-enhanced',
    default  => 'vim',
  }

  ensure_packages([$vim, 'htop', 'iftop', 'screen', 'ruby-shadow'])

  # TODO: rsync package is managed by puppetlabs-rsync

  mailalias { 'sysadmins':
    ensure    => present,
    recipient => $sysadmins,
  }
  mailalias { 'root':
    ensure    => present,
    recipient => 'sysadmins',
  }
}
