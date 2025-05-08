# @summary install JJB
# @api private
class jenkins_job_builder::install (
  String[1] $ensure = $jenkins_job_builder::ensure,
) {
  stdlib::ensure_packages(['python3-pip', 'python3-pyyaml'])

  package { 'jenkins-job-builder':
    ensure   => $jenkins_job_builder::ensure,
    provider => 'pip',
    require  => Package['python3-pip', 'python3-pyyaml'],
  }

  file { '/etc/jenkins_jobs':
    ensure => directory,
  }
}
