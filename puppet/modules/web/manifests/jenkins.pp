class web::jenkins(
  $hostname = 'ci.theforeman.org',
  $webroot = '/var/www/vhosts/jenkins/htdocs',
) {
  include apache

  $proxy_pass = {
    'path'     => '/',
    'url'      => 'http://localhost:8080/',
    'keywords' => ['nocanon'],
  }

  apache::vhost { 'jenkins':
    port       => '80',
    servername => $hostname,
    docroot    => $webroot,
    proxy_pass => $proxy_pass,
  }
}
