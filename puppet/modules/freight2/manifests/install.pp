class freight2::install {

  if $::operatingsystem == 'Debian' {
    apt::source { 'freight':
      location    => 'http://packages.rcrowley.org',
      release     => 'squeeze',
      repos       => 'main',
      key         => '7DF49CEF',
      key_source  => 'http://packages.rcrowley.org/keyring.gpg',
      include_src => false,
    }->
    package { 'freight':
      ensure  => installed,
    }
  } else {
    package { 'freight':
      provider => 'rpm',
      ensure   => installed,
      source   => "http://skottler.fedorapeople.org/packages/freight-0.3.2-1.x86_64.rpm",
    }
    package { 'dpkg': ensure => installed }
  }

}
