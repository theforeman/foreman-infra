# @api private
define slave::rvm_config (
  String[1] $version,
  Enum['present', 'absent'] $ensure = 'present',
  String[1] $rubygems_version = '3.0.6',
  Optional[String[1], Undef] $build_opts = undef,
) {
  $alias = $title

  rvm_system_ruby { $version:
    ensure     => $ensure,
    build_opts => $build_opts,
  }

  rvm_alias { $alias:
    ensure      => $ensure,
    target_ruby => $version,
  }

  if $ensure == 'present' {
    Rvm_system_ruby[$version] -> Rvm_alias[$alias]
    -> exec { "${version}/update_rubygems":
      command  => "rvm ${version} rubygems ${rubygems_version} --force",
      unless   => "test `rvm ${version} do gem -v` = ${rubygems_version}",
      path     => '/usr/local/rvm/bin:/usr/bin:/bin',
      provider => 'shell',
    }
  } else {
    Rvm_alias[$alias] -> Rvm_system_ruby[$version]
  }
}
