class slave::docker {
  file { '/etc/systemd/system/docker.service.d/service-overrides.conf':
    ensure => absent,
  }

  package { 'docker-ce':
    ensure => absent,
  } ->
  file { '/etc/yum.repos.d/docker.repo':
    ensure => absent,
  } ->
  class { 'docker':
    use_upstream_package_source => false,
    service_overrides_template  => false,
    docker_ce_package_name      => $::osfamily ? {
      'Debian' => 'docker.io',
      default  => 'docker',
    };
  }
}
