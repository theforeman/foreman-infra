# Class to install, configure, and maintain JJB, as well
# as to deploy the actual jobs to jenkins
#
# Loosely based on
# https://git.openstack.org/cgit/openstack-infra/puppet-jenkins/tree/manifests/job_builder.pp
# and should probably be kept up to date from there
#
# $configs is a hash of:
#   'name' => 'url', 'username', 'password', 'run'
#
# $name matches the name under files/ of the config directory.
# $run is our addition and is so named becuase noop is a bit too magic in puppet syntax...
#
class jenkins_job_builder (
  $configs                     = {},
  $git_revision                = 'master',
  $git_url                     = 'https://github.com/theforeman/jenkins-job-builder',
  $jenkins_jobs_update_timeout = '600',
) {
  validate_hash($configs)

  $defaults = { 'jenkins_jobs_update_timeout' => $jenkins_jobs_update_timeout }
  create_resources('jenkins_job_builder::config', $configs, $defaults)

  class { '::jenkins_job_builder::install': } ~> Jenkins_job_builder::Config <| |>

  # used to run an update on a regular schedule, in the early morning
  schedule { 'jenkins':
    range  => '2 - 4',
    period => daily,
    repeat => 1,
  }
}
