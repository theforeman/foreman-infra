# @summary The profile for a Jenkins controller (formerly master)
#
# @param hostname
#   The hostname to use in the Apache vhost
# @param https
#   Whether to serve on HTTPS. If so, the HTTP vhost becomes a redirect to HTTPS.
# @param jenkins_job_builder
#   Whether to run Jenkins Job Builder
# @param jenkins_job_builder_username
#   The username Jenkins Job Builder should use if enabled
# @param jenkins_job_builder_password
#   The password Jenkins Job Builder should use if enabled
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
  Boolean $jenkins_job_builder = true,
  Optional[String] $jenkins_job_builder_username = undef,
  Optional[String] $jenkins_job_builder_password = undef,
  Array[String[1]] $packages = ['java-17-openjdk-headless', 'java-17-openjdk-devel', 'fontconfig'],
  Array[String[1]] $plugins = [],
) {
  stdlib::ensure_packages($packages)

  package { ['java-11-openjdk', 'java-11-openjdk-headless', 'java-11-openjdk-devel']:
    ensure => absent,
  }
  Package['java-11-openjdk-devel'] -> Package['java-11-openjdk'] -> Package['java-11-openjdk-headless']

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

  if $jenkins_job_builder {
    class { 'jenkins_job_builder':
      configs => {
        'theforeman.org' => {
          url      => $web::jenkins::url,
          username => $jenkins_job_builder_username,
          password => $jenkins_job_builder_password,
        },
      },
      require => [Class['jenkins', 'web::jenkins']],
    }
  }
}
