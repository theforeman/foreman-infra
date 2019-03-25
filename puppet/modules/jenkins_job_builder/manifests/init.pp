# Class to install, configure, and maintain JJB, as well
# as to deploy the actual jobs to jenkins
#
# Loosely based on
# https://git.openstack.org/cgit/openstack-infra/puppet-jenkins/tree/manifests/job_builder.pp
# and should probably be kept up to date from there
#
# @param configs
#   A hash of: 'name' => 'url', 'username', 'password'
#   The name matches the name under files/ of the config directory.
#
class jenkins_job_builder (
  Hash[String, Hash] $configs = {},
) {
  contain jenkins_job_builder::install

  $configs.each |$config, $params| {
    jenkins_job_builder::config { $config:
      *         => $params,
      subscribe => Class['jenkins_job_builder::install'],
    }
  }
}
