# @api private
class jenkins_node::packaging (
  Boolean $uploader,
  Stdlib::Absolutepath $homedir,
  Stdlib::Absolutepath $workspace,
) {
  # CLI JSON parser
  package { 'jq':
    ensure => installed,
  }

  case $facts['os']['family'] {
    'RedHat': {
      class { 'jenkins_node::packaging::rpm':
        homedir   => $homedir,
        user      => 'jenkins',
        workspace => $workspace,
      }
      contain jenkins_node::packaging::rpm
    }
    'Debian': {
      class { 'jenkins_node::packaging::debian':
        uploader  => $uploader,
        user      => 'jenkins',
        workspace => $workspace,
      }
      contain jenkins_node::packaging::debian
    }
    default: {}
  }
}
