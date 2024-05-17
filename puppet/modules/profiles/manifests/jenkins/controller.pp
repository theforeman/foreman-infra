# @summary The profile for a Jenkins controller (formerly master)
#
# @param hostname
#   The hostname to use in the Apache vhost
# @param https
#   Whether to serve on HTTPS. If so, the HTTP vhost becomes a redirect to HTTPS.
# @param packages
#   The (java) packages to install. OpenJDK Devel is needed for jar unpacking support.
# @param plugins
#   The list of plugins. Get the list by going to /script on jenkins and run:
#     Jenkins.instance.pluginManager.plugins.toArray().sort { plugin -> plugin.getShortName()}.each {
#       plugin -> println ("    '${plugin.getShortName()}' => {},")
#     }
class profiles::jenkins::controller (
  Stdlib::Fqdn $hostname = 'ci.theforeman.org',
  Boolean $https = true,
  Array[String[1]] $packages = ['java-11-openjdk-headless', 'java-11-openjdk-devel', 'fontconfig'],
  Array[String[1]] $plugins = [],
) {
  ensure_packages($packages)

  class { 'jenkins':
    install_java    => false,
    lts             => true,
    default_plugins => [],
    plugin_hash     => $plugins.reduce({}) |Hash $memo, String $plugin| { $memo + { $plugin => {} } },
    config_hash     => {
      'JENKINS_JAVA_OPTIONS' => {
        'value' => '-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false -Xms2048m -Xmx2048m',
      },
    },
    require         => Package[$packages],
  }

  class { 'web::base':
    letsencrypt => $https,
  }

  class { 'web::jenkins':
    hostname => $hostname,
    https    => $https,
  }

  include profiles::backup::sender

  $backup_path = $jenkins::localstatedir

  restic::repository { 'jenkins':
    backup_cap_dac_read_search => true,
    backup_path                => $backup_path,
    backup_flags               => [
      '--exclude', "${backup_path}/jobs/*/workspace*",
      '--exclude', "${backup_path}/jobs/*/builds",
      '--exclude', "${backup_path}/plugins",
    ],
  }
}
