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

  # msgfmt and make, used to compile gettext catalogs (locale/*.po -> *.mo)
  # before building gem sources. Gemspecs package locale/ by filesystem glob,
  # so the catalogs must exist on disk at build time or the gem ships without
  # them and the plugin's strings render untranslated.
  package { ['gettext', 'make']:
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
