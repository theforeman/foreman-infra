# Class for configuring the Apache proxy in front of Shiny Server
#
# === Parameters:
#
# $hostname::       FQDN for LetsEncrypt
#
# $webroot::        Location of the DocumentRoot (htdocs etc) folder
#
# $https::          Whether to enable the https vhost. Also redirects traffic from http
#
class web::stats(
  String $hostname              = 'stats.theforeman.org',
  Stdlib::Absolutepath $webroot = '/var/www/vhosts/shiny/htdocs',
  Boolean $https                = false,
) {
  include ::web::base

  $proxy_pass = {
    'path'          => '/',
    'url'           => 'http://localhost:3838/',
    'keywords'      => ['nocanon'],
    'no_proxy_uris' => ['/.well-known'],
  }

  letsencrypt::certonly { $hostname:
    plugin        => 'webroot',
    manage_cron   => false,
    domains       => [$hostname],
    webroot_paths => [$webroot],
  }

  if $https {
    apache::vhost { 'shiny-server':
      port          => '80',
      servername    => $hostname,
      docroot       => $webroot,
      docroot_owner => $::apache::user,
      docroot_group => $::apache::group,
      redirect_dest => "https://${servername}/",
    }
    apache::vhost { 'shiny_server-https':
      port          => 443,
      servername    => $hostname,
      docroot       => $webroot,
      docroot_owner => $::apache::user,
      docroot_group => $::apache::group,
      proxy_pass    => $proxy_pass,
      ssl           => true,
      ssl_cert      => "/etc/letsencrypt/live/${hostname}/fullchain.pem",
      ssl_chain     => "/etc/letsencrypt/live/${hostname}/chain.pem",
      ssl_key       => "/etc/letsencrypt/live/${hostname}/privkey.pem",
      require       => Letsencrypt::Certonly[$hostname],
    }
  } else {
    apache::vhost { 'shiny_server':
      port          => '80',
      servername    => $hostname,
      docroot       => $webroot,
      docroot_owner => $::apache::user,
      docroot_group => $::apache::group,
      proxy_pass    => $proxy_pass,
    }
  }

}
