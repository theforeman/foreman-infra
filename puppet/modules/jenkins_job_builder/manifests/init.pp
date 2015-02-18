# Class to install, configure, and maintain JJB, as well
# as to deploy the actual jobs to jenkins
#
# Loosely based on
# https://git.openstack.org/cgit/openstack-infra/puppet-jenkins/tree/manifests/job_builder.pp
# and should probably be kept up to date from there
#
# $run is our addition and is so named becuase noop is a bit too magic in puppet syntax...
#
class jenkins_job_builder (
  $url = '',
  $username = '',
  $password = '',
  $config_dir = '',
  $run = 'false',
) {

  if ! defined(Package['jenkins-job-builder']) {
    package { 'jenkins-job-builder':
      ensure   => present,
      provider => 'pip',
    }
  }

  file { '/etc/jenkins_jobs':
    ensure => directory,
  }

  file { '/etc/jenkins_jobs/config':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    source  => $config_dir,
    notify  => Exec['jenkins_jobs_update'],
  }

  # test for a string here since it's annoyingly hard to pass a boolean from foreman via yaml
  if $run == 'false' {
    $cmd = "jenkins-jobs test /etc/jenkins_jobs/config > /var/cache/jjb.xml"
  }else{
    $cmd = "jenkins-jobs update /etc/jenkins_jobs/config > /var/cache/jjb.xml"
    # eventually we may wish to nuke unmanaged jobs:
    #$cmd = "jenkins-jobs update --delete-old /etc/jenkins_jobs/config > /var/cache/jjb.xml"
  }

  exec { 'jenkins_jobs_update':
    command     => $cmd,
    timeout     => '600',
    path        => '/bin:/usr/bin:/usr/local/bin',
    refreshonly => true,
    require     => [
      File['/etc/jenkins_jobs/jenkins_jobs.ini'],
      Package['jenkins-job-builder'],
    ],
  }

# TODO: We should put in  notify Exec['jenkins_jobs_update']
#       at some point, but that still has some problems.
  file { '/etc/jenkins_jobs/jenkins_jobs.ini':
    ensure  => present,
    mode    => '0400',
    content => template('jenkins_job_builder/jenkins_jobs.ini.erb'),
  }
}
