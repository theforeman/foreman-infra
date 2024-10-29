class web::jenkins (
  Stdlib::Fqdn $hostname = 'ci.theforeman.org',
) {
  $proxy_attrs = {
    'allow_encoded_slashes' => 'nodecode',
    'proxy_pass' => {
      'path'          => '/',
      'url'           => 'http://localhost:8080/',
      'keywords'      => ['nocanon'],
      'no_proxy_uris' => ['/.well-known'],
    },
  }

  if $facts['os']['selinux']['enabled'] {
    selboolean { 'httpd_can_network_connect':
      persistent => true,
      value      => 'on',
    }
  }

  include web

  if $web::https {
    $http_attrs = {
      'redirect_dest' => "https://${hostname}/",
    }
    $https_attrs = $proxy_attrs
  } else {
    $http_attrs = $proxy_attrs
    $https_attrs = {}
  }

  web::vhost { 'jenkins':
    servername  => $hostname,
    http_attrs  => $http_attrs,
    https_attrs => $https_attrs,
    attrs       => {
      'request_headers' => ['set X-Forwarded-Proto expr=%{REQUEST_SCHEME}'],
    },
  }
}
