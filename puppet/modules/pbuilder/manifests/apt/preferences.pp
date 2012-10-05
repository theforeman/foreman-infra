define pbuilder::apt::preferences (
  $pbuilder_name,
  $pbuilder_type='pbuilder',
  $ensure="present",
  $package="",
  $pin,
  $priority
) {

  $pkg = $package ? {
    "" => $name,
    default => $package,
  }

  $fname = regsubst($name, '\.', '-', 'G')

  # apt support preferences.d since version >= 0.7.22
  # but we can't simply test for the version used in the pbuilder
  # so we just concatenate
  concat::fragment {$fname:
      ensure  => $ensure,
      target  => "/etc/pbuilder/${pbuilder_name}/apt/preferences",
      content => template("apt/preferences.erb"),
      notify  => Exec["update ${pbuilder_type} ${pbuilder_name}"],
  }

}
