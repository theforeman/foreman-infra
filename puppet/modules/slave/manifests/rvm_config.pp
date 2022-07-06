# @api private
define slave::rvm_config (
  String[1] $version,
  String[1] $rubygems_version = '3.0.6',
) {
  $alias = $title

  rvm_system_ruby { $version:
    ensure => present,
  } ->
  rvm_alias { $alias:
    ensure      => present,
    target_ruby => $version,
  } ->
  exec { "${version}/update_rubygems":
    command  => "rvm ${version} rubygems ${rubygems_version} --force",
    unless   => "test `rvm ${version} do gem -v` = ${rubygems_version}",
    path     => '/usr/local/rvm/bin:/usr/bin:/bin',
    provider => 'shell',
  }
}
