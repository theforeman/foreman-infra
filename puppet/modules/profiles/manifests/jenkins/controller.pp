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
class profiles::jenkins::controller (
  Stdlib::Fqdn $hostname = 'ci.theforeman.org',
  Boolean $https = true,
  Boolean $jenkins_job_builder = true,
  Optional[String] $jenkins_job_builder_username = undef,
  Optional[String] $jenkins_job_builder_password = undef,
) {
  include jenkins_master

  class { 'web::base':
    letsencrypt => $https,
  }

  class { 'web::jenkins':
    hostname => $hostname,
    https    => $https,
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
      require => [Class['jenkins_master', 'web::jenkins']],
    }
  }
}
