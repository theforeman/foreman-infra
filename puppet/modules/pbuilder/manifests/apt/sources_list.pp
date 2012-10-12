define pbuilder::apt::sources_list (
  $pbuilder_name,
  $ensure='present',
  $source=false,
  $content=false,
  $pbuilder_type='pbuilder',
  $filename=''
) {

  $file = $filename ? {
    ''      => "/etc/pbuilder/${pbuilder_name}/apt/sources.list.d/${name}.list",
    default => "/etc/pbuilder/${pbuilder_name}/apt/sources.list.d/${filename}.list",
  }

  if $source {
    file {$file:
      ensure => $ensure,
      source => $source,
      notify => Exec["update ${pbuilder_type} ${pbuilder_name}"],
    }
  } else {
    file {$file:
      ensure  => $ensure,
      content => $content,
      notify => Exec["update ${pbuilder_type} ${pbuilder_name}"],
    }
  }
}
