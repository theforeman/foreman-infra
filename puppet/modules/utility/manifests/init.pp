# Various basic utilities
class utility {
  include motd
  include unattended

  $vim = $facts['os']['family'] ? {
    'RedHat' => 'vim-enhanced',
    default  => 'vim',
  }

  ensure_packages([$vim])

  unless $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '8' {
    ensure_packages(['htop', 'iftop', 'screen'])
  }

  # TODO: rsync package is managed by puppetlabs-rsync
}
