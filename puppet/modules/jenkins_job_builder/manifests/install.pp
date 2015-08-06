# Class to install, configure, and maintain JJB
#
# Loosely based on
# https://git.openstack.org/cgit/openstack-infra/puppet-jenkins/tree/manifests/job_builder.pp
# and should probably be kept up to date from there
class jenkins_job_builder::install {
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

  vcsrepo { '/opt/jenkins_job_builder':
    ensure   => latest,
    provider => git,
    revision => $::jenkins_job_builder::git_revision,
    source   => $::jenkins_job_builder::git_url,
  }
  ~>
  exec { 'install_jenkins_job_builder':
    command     => 'pip install /opt/jenkins_job_builder',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
  }

  file { '/etc/jenkins_jobs':
    ensure => directory,
  }
}
