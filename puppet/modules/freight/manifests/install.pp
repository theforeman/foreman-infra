class freight::install {

  if $::osfamily == 'Debian' {
    apt::source { 'freight':
      location    => 'http://build.openvpn.net/debian/freight_team',
      release     => $::lsbdistcodename,
      repos       => 'main',
      key         => '30EBF4E73CCE63EEE124DD278E6DA8B4E158C569',
      key_source  => 'https://swupdate.openvpn.net/repos/repo-public.gpg',
      include_src => false,
    }->
    package { 'freight':
      ensure => installed,
    }
  } else {
    # There used to be a copr for this but it's in EPEL now
    yumrepo { 'freight':
      ensure => absent,
    }

    package { 'freight':
      ensure => 'latest',
    }
  }

}
