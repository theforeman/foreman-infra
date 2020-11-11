node /^jenkins-master.*/ {
  class { 'profiles::jenkins::controller':
    hostname                     => $facts['networking']['fqdn'],
    https                        => false,
    jenkins_job_builder          => true,
    jenkins_job_builder_username => 'admin',
    jenkins_job_builder_password => 'changeme',
  }
}

node /^web.*/ {
  class { 'profiles::web':
    https => false,
  }
}
