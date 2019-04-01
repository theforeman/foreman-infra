# Class to install, configure, and maintain JJB
#
# Loosely based on
# https://git.openstack.org/cgit/openstack-infra/puppet-jenkins/tree/manifests/job_builder.pp
# and should probably be kept up to date from there
class jenkins_job_builder::install {
  ensure_packages(['python-pip'])

  Package['python-pip'] -> Package <| provider == 'pip' |>

  # A lot of things need yaml, be conservative requiring this package to avoid
  # conflicts with other modules.
  if ! defined(Package['PyYAML']) {
    package { 'PyYAML':
      ensure => present,
    }
  }

  if ! defined(Package['python-jenkins']) {
    package { 'python-jenkins':
      ensure   => present,
      provider => 'pip',
    }
  }

  package { 'jenkins-job-builder':
    ensure   => present,
    provider => 'pip',
  }

  file { '/etc/jenkins_jobs':
    ensure => directory,
  }
}
