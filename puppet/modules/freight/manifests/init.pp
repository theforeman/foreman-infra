# @summary install freight
class freight {
  if $facts['os']['family'] == 'Debian' {
    apt::source { 'freight':
      location => 'http://build.openvpn.net/debian/freight_team',
      repos    => 'main',
      key      => {
        id     => '30EBF4E73CCE63EEE124DD278E6DA8B4E158C569',
        source => 'https://swupdate.openvpn.net/repos/repo-public.gpg',
      },
      before   => Package['freight'],
    }
  }

  package { 'freight':
    ensure => 'installed',
  }
}
