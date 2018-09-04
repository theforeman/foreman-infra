class web::stats(
  $hostname = 'stats.theforeman.org',
  $webroot = '/var/www/vhosts/shiny/htdocs',
  $https = false,
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

  apache::vhost { 'shiny_server':
    port          => '80',
    servername    => $hostname,
    docroot       => $webroot,
    docroot_owner => $::apache::user,
    docroot_group => $::apache::group,
    proxy_pass    => $proxy_pass,
  }

  if $https {
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
  }
}
