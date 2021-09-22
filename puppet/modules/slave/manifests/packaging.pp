# @api private
class slave::packaging(
  Boolean $uploader,
  Stdlib::Absolutepath $homedir,
  Stdlib::Absolutepath $workspace,
  Optional[String] $koji_certificate = undef,
) {

  # CLI JSON parser
  package { 'jq':
    ensure => installed,
  }

  case $facts['os']['family'] {
    'RedHat': {
      class { 'slave::packaging::rpm':
        homedir          => $homedir,
        koji_certificate => $koji_certificate,
      }
      contain slave::packaging::rpm
    }
    'Debian': {
      class { 'slave::packaging::debian':
        uploader  => $uploader,
        user      => 'jenkins',
        workspace => $workspace,
      }
      contain slave::packaging::debian
    }
    default: {}
  }

}
