# Various basic utilities
class utility {
  $vim = $facts['os']['family'] ? {
    'RedHat' => 'vim-enhanced',
    default  => 'vim',
  }

  stdlib::ensure_packages([$vim])

  stdlib::ensure_packages(['htop', 'iftop', 'tmux'])

  stdlib::ensure_packages(['rsync'])
}
