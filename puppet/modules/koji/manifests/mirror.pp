# Basic mirror for Koji
class koji::mirror (
  Stdlib::Fqdn $servername,
  Stdlib::Absolutepath $mirror_root,
  String $entitlement_id,
  Array[Stdlib::Fqdn] $serveraliases = [],
  Optional[Array[String]] $access_require = undef,
){
  ensure_packages(['dnf-plugins-core'])

  file { $mirror_root:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if $facts['os']['selinux']['enabled'] {
    include selinux

    selinux::fcontext { $mirror_root:
      seltype  => 'httpd_sys_content_t',
      pathspec => "${mirror_root}(/.*)?",
      notify   => File[$mirror_root],
    }
  }

  file { '/etc/reposync.conf':
    content => epp('koji/mirror_reposync.conf.epp', { 'entitlement_id' => $entitlement_id }),
    mode    => '0644',
  }

  file { '/etc/cron.weekly/reposync':
    content => epp('koji/mirror_reposync.cron.epp', { 'mirror_root' => $mirror_root }),
    mode    => '0755',
    require => [File[$mirror_root, '/etc/reposync.conf'], Package['dnf-plugins-core']],
  }

  class { 'apache':
    default_vhost => false,
  }

  apache::vhost { $servername:
    serveraliases => $serveraliases,
    port          => 80,
    docroot       => $mirror_root,
    directories   => [
      {
        'path'    => $mirror_root,
        'require' => $access_require,
      },
    ],
  }
}
