class freight::install {

  if $::osfamily == 'Debian' {
    apt::source { 'freight':
      location    => 'http://packages.rcrowley.org',
      release     => $::lsbdistcodename,
      repos       => 'main',
      key         => '7DF49CEF',
      key_source  => 'http://packages.rcrowley.org/keyring.gpg',
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
