define slave::rvm_config($version, $rubygems_version = '2.4.5') {
  $alias = $title

  rvm_system_ruby { $version:
    ensure => present,
  } ->
  rvm_alias { $alias:
    ensure      => present,
    target_ruby => $version,
  } ->
  rvm_gem { "${version}/rubygems-update":
    ensure => $rubygems_version,
  } ~>
  exec { "${version}/update_rubygems":
    command  => "rvm ${version} do update_rubygems",
    unless   => "test `rvm ${version} do gem -v` = ${rubygems_version}",
    path     => '/usr/local/rvm/bin:/usr/bin:/bin',
    provider => 'shell',
  }
}
