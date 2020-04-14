# @api private
class slave::docker {
  file { '/etc/systemd/system/docker.service.d/service-overrides.conf':
    ensure => absent,
  }

  $docker_ce_package_name = $facts['os']['family'] ? {
    'Debian' => 'docker.io',
    default  => 'docker',
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
    docker_ce_package_name      => $docker_ce_package_name,
  }

  group { 'docker':
    ensure => 'present',
  }

  User<|title == 'jenkins'|>{groups +> ['docker']}
}
