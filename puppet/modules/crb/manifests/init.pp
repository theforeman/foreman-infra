# @summary Enable the CRB repository on a RedHat family system
class crb {
  if $facts['os']['family'] == 'RedHat' {
    yumrepo { 'crb':
      enabled => '1',
    }
  }
}
