class web::jenkins(
  Stdlib::Fqdn $hostname = 'ci.theforeman.org',
  Stdlib::Absolutepath $webroot = '/var/www/vhosts/jenkins/htdocs',
  Boolean $https = false,
) {
  include ::web::base

  $proxy_pass = {
    'path'          => '/',
    'url'           => 'http://localhost:8080/',
    'keywords'      => ['nocanon'],
    'no_proxy_uris' => ['/.well-known'],
  }

  if $web::base::letsencrypt {
    letsencrypt::certonly { $hostname:
      plugin        => 'webroot',
      domains       => [$hostname],
      webroot_paths => [$webroot],
    }
  }

  if $facts['selinux'] {
    selboolean { 'httpd_can_network_connect':
      persistent => true,
      value      => 'on',
    }
  }

  file { dirname($webroot):
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if $web::base::letsencrypt and $https {
    apache::vhost { 'jenkins':
      port          => 80,
      servername    => $hostname,
      docroot       => $webroot,
      docroot_owner => $::apache::user,
      docroot_group => $::apache::group,
      redirect_dest => "https://${hostname}/",
    }
    apache::vhost { 'jenkins-https':
      port                  => 443,
      servername            => $hostname,
      docroot               => $webroot,
      docroot_owner         => $::apache::user,
      docroot_group         => $::apache::group,
      proxy_pass            => $proxy_pass,
      allow_encoded_slashes => 'nodecode',
      request_headers       => ['set X-Forwarded-Proto "https"'],
      ssl                   => true,
      ssl_cert              => "/etc/letsencrypt/live/${hostname}/fullchain.pem",
      ssl_chain             => "/etc/letsencrypt/live/${hostname}/chain.pem",
      ssl_key               => "/etc/letsencrypt/live/${hostname}/privkey.pem",
      require               => Letsencrypt::Certonly[$hostname],
    }
  } else {
    apache::vhost { 'jenkins':
      port                  => 80,
      servername            => $hostname,
      docroot               => $webroot,
      docroot_owner         => $::apache::user,
      docroot_group         => $::apache::group,
      proxy_pass            => $proxy_pass,
      allow_encoded_slashes => 'nodecode',
    }
  }
}
