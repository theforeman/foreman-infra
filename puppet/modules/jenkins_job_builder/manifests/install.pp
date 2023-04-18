# @summary install JJB
# @api private
class jenkins_job_builder::install (
  String[1] $ensure = $jenkins_job_builder::ensure,
) {
  $yaml = if $facts['os']['release']['major'] == '7' { 'PyYAML' } else { 'python3-pyyaml' }
  ensure_packages(['python-pip', $yaml])

  package { 'jenkins-job-builder':
    ensure   => $jenkins_job_builder::ensure,
    provider => 'pip',
    require  => Package['python-pip', $yaml],
  }

  file { '/etc/jenkins_jobs':
    ensure => directory,
  }
}
