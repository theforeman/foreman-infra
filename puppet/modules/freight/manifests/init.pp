# @summary install freight
class freight {
  if $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '9' {
    yumrepo { 'evgeni_freight':
      baseurl  => "https://download.copr.fedorainfracloud.org/results/evgeni/freight/epel-${facts['os']['release']['major']}-\$basearch/",
      descr    => 'evgeni/freight',
      enabled  => true,
      gpgcheck => true,
      gpgkey   => 'https://download.copr.fedorainfracloud.org/results/evgeni/freight/pubkey.gpg',
      before   => Package['freight'],
    }
  }

  package { 'freight':
    ensure => 'installed',
  }
}
