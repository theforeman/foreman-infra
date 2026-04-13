# @summary Define a vhost
#
# Defines a vhost on port 80 and a https vhost on port 443 if enabled in the
# web class.
#
# @param servername
#   The servername on the vhost
# @param serveraliases
#   Alternative names for this vhost
# @param directories
#   The directories to set. This maps to apache::vhost's directories parameter
#   and can also be used to set locations.
# @param docroot
#   The docroot
# @param docroot_owner
#   The docroot owner, if any
# @param docroot_group
#   The docroot group, if any
# @param docroot_mode
#   The docroot mode, if any
# @param ensure
#   Whether the vhost should be present or absent
# @param attrs
#   Attributes that should be passed to the vhost and https vhost
define web::vhost (
  Enum['present', 'absent'] $ensure = 'present',
  Stdlib::Fqdn $servername = "${title}.theforeman.org",
  Array[Stdlib::Fqdn] $serveraliases = [],
  Optional[Array[Hash]] $directories = undef,
  Stdlib::Absolutepath $docroot = "/var/www/vhosts/${title}/htdocs",
  Optional[String] $docroot_owner = undef,
  Optional[String] $docroot_group = undef,
  Optional[Stdlib::Filemode] $docroot_mode = undef,
  Hash[String, Any] $attrs = {},
  Hash[String, Any] $http_attrs = {},
  Hash[String, Any] $https_attrs = {},
) {
  require web

  $directory_ensure = $ensure ? {
    'present' => 'directory',
    'absent'  => 'absent',
  }

  file { dirname($docroot):
    ensure => $directory_ensure,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  apache::vhost { $title:
    ensure        => $ensure,
    servername    => $servername,
    serveraliases => $serveraliases,
    port          => 80,
    directories   => $directories,
    docroot       => $docroot,
    docroot_owner => $docroot_owner,
    docroot_group => $docroot_group,
    docroot_mode  => $docroot_mode,
    *             => $http_attrs + $attrs,
  }

  if $web::https {
    include web::letsencrypt

    letsencrypt::certonly { $servername:
      ensure        => $ensure,
      plugin        => 'webroot',
      domains       => [$servername] + $serveraliases,
      webroot_paths => [$docroot],
    }

    apache::vhost { "${title}-https":
      ensure        => $ensure,
      servername    => $servername,
      serveraliases => $serveraliases,
      directories   => $directories,
      docroot       => $docroot,
      docroot_owner => $docroot_owner,
      docroot_group => $docroot_group,
      docroot_mode  => $docroot_mode,
      port          => 443,
      ssl           => true,
      ssl_cert      => "${letsencrypt::config_dir}/live/${servername}/cert.pem",
      ssl_chain     => "${letsencrypt::config_dir}/live/${servername}/chain.pem",
      ssl_key       => "${letsencrypt::config_dir}/live/${servername}/privkey.pem",
      require       => Letsencrypt::Certonly[$servername],
      *             => $https_attrs + $attrs,
    }
  }
}
