# Various basic utilities
class utility($sysadmins = ['/dev/null']) {
  include motd
  include unattended

  $vim = $facts['os']['family'] ? {
    'RedHat' => 'vim-enhanced',
    default  => 'vim',
  }

  if $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '8' {
    $additional_packages = []
  } else {
    $additional_packages = ['htop', 'iftop', 'screen']
  }
  ensure_packages([$vim] + $additional_packages)

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
