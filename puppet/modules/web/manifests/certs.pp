# @summary Define letsencrypt certificate
#
# domain / webroot_paths must match exactly
#
# @param domains
#   Domains to be handled by the certificate
# @param paths
#   Vhost paths for each domain
define web::certs(
  Array[String] $domains,
  Array[String] $paths,
) {
  $letsencypt_domain = 'theforeman.org'

  letsencrypt::certonly { $letsencypt_domain:
    plugin        => 'webroot',
    domains       => $domains,
    webroot_paths => $paths,
  }
}
