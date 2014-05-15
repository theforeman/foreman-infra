define slave::rvm_config($version) {
  $alias = $title

  rvm_system_ruby { $version:
    ensure => present,
  }

  rvm_alias { $alias:
    ensure      => present,
    target_ruby => $version,
    require     => Rvm_system_ruby[$version],
  }
}
