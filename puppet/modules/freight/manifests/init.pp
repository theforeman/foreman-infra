# @summary install freight
class freight {
  if $facts['os']['family'] == 'RedHat' {
    include epel
    Class['Epel'] -> Package['freight']
  }

  package { 'freight':
    ensure => 'installed',
  }
}
