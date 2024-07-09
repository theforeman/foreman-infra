# Various basic utilities
class utility($sysadmins = ['/dev/null']) {
  $vim = $facts['os']['family'] ? {
    'RedHat' => 'vim-enhanced',
    default  => 'vim',
  }

  stdlib::ensure_packages([$vim])

  stdlib::ensure_packages(['htop', 'iftop', 'screen'])

  stdlib::ensure_packages(['rsync'])

  mailalias { 'sysadmins':
    ensure    => present,
    recipient => $sysadmins,
  }
  mailalias { 'root':
    ensure    => present,
    recipient => 'sysadmins',
  }
}
