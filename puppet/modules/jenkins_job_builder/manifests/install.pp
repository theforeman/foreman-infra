# Class to install, configure, and maintain JJB
#
# Loosely based on
# https://git.openstack.org/cgit/openstack-infra/puppet-jenkins/tree/manifests/job_builder.pp
# and should probably be kept up to date from there
class jenkins_job_builder::install {
  ensure_packages(['python3-pip'])

  Package['python3-pip'] -> Package <| provider == 'pip3' |>

  package { 'python36-PyYAML':
    ensure => present,
  }

  package { 'jenkins-job-builder':
    ensure   => present,
    provider => 'pip3',
    require  => Package['python36-PyYAML'],
  }

  file { '/etc/jenkins_jobs':
    ensure => directory,
  }
}
