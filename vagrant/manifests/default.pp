node 'jenkins-master' {
  include jenkins_master

  class { 'web::base':
    letsencrypt => false,
  }

  class { 'web::jenkins':
    hostname => $facts['fqdn'],
  }

  class { 'jenkins_job_builder':
    configs => {
      'theforeman.org' => {
        url      => "http://${web::jenkins::hostname}",
        username => 'admin',
        password => 'changeme',
      }
    },
    require => [Class['jenkins_master', 'web::jenkins']],
  }
}

node /^web.*/ {
  class { 'profiles::web':
    https => false,
  }
}
