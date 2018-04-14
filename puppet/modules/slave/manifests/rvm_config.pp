define slave::rvm_config($version, $rubygems_version = '2.7.6') {
  $alias = $title

  rvm_system_ruby { $version:
    ensure => present,
  } ->
  rvm_alias { $alias:
    ensure      => present,
    target_ruby => $version,
  } ->
  exec { "${version}/update_rubygems":
    command  => "rvm ${version} rubygems ${rubygems_version}",
    unless   => "test `rvm ${version} do gem -v` = ${rubygems_version}",
    path     => '/usr/local/rvm/bin:/usr/bin:/bin',
    provider => 'shell',
  }
}
