# Various basic utilities
class utility($sysadmins = ['/dev/null']) {
  $vim = $facts['os']['family'] ? {
    'RedHat' => 'vim-enhanced',
    default  => 'vim',
  }

  stdlib::ensure_packages([$vim])

  unless $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '8' {
    stdlib::ensure_packages(['htop', 'iftop', 'screen'])
  }

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
