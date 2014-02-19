class web::jenkins($hostname = 'ci.theforeman.org') {
  apache::vhost { 'jenkins':
    ensure         => present,
    config_content => template('web/jenkins.conf.erb'),
  }
}
