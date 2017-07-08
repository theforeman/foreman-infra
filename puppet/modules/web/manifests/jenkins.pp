class web::jenkins($hostname = 'ci.theforeman.org') {
  include apache
  include apache::mod::proxy
  include apache::mod::proxy_http

  apache::vhost { 'jenkins':
    port            => '80',
    servername      => $hostname,
    docroot         => '/var/www/vhosts/jenkins/htdocs',
    custom_fragment => template('web/jenkins.conf.erb'),
    keepalive       => 'on',
  }
}
