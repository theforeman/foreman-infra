#
# == Class: tito
#
# Installs tito, a tool for building RPM's in an automated fashion.
#
# Example usage:
#   include tito
#
class tito {
  case $::operatingsystem {
    'RedHat', 'CentOS', 'Fedora': {
      package {
        'asciidoc':
          ensure   => present;
        'tito':
          ensure   => present,
          provider => 'rpm',
          source   => 'http://skottler.fedorapeople.org/packages/tito-0.4.11-1.el6.noarch.rpm',
      }
    }
    # Just skip it if the OS isn't supported.
    default: {}
  }
}
