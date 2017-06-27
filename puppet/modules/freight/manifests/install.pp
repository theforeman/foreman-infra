class freight::install {

  if $::operatingsystem == 'Debian' {
    apt::source { 'freight':
      location    => 'http://packages.rcrowley.org',
      release     => 'wheezy',
      repos       => 'main',
      key         => '7DF49CEF',
      key_source  => 'http://packages.rcrowley.org/keyring.gpg',
      include_src => false,
    }->
    package { 'freight':
      ensure => installed,
    }
  } else {
    yumrepo { 'freight':
      descr    => 'Freight',
      baseurl  => 'http://copr-be.cloud.fedoraproject.org/results/domcleal/freight/epel-6-$basearch/',
      gpgcheck => '0',
      enabled  => '1',
    } ->
    package { 'freight':
      ensure => 'latest',
    }
  }

}
