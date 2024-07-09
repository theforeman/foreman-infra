# Various basic utilities
class utility {
  $vim = $facts['os']['family'] ? {
    'RedHat' => 'vim-enhanced',
    default  => 'vim',
  }

  stdlib::ensure_packages([$vim])

  unless $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '8' {
    stdlib::ensure_packages(['htop', 'iftop', 'screen'])
  }

  stdlib::ensure_packages(['rsync'])
}
