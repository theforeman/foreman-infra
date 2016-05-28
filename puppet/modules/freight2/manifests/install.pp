class freight::install {

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
      ensure   => installed,
      provider => 'gem'
    }
  }

}
