define debian::pbuilder_setup (
  $ensure     = present,
  $backports  = false,
  $nodesource = false,
  $puppetlabs = true,
  $arch,
  $release,
  $apturl,
  $aptcontent,
) {

  pbuilder { $name:
    ensure    => $ensure,
    arch      => $arch,
    release   => $release,
    methodurl => $apturl,
  }

  file { "/etc/pbuilder/${name}/apt.config/sources.list.d":
    ensure  => directory,
  }

  file { "/etc/pbuilder/${name}/apt.config/sources.list.d/debian.list":
    ensure  => $ensure,
    notify  => Exec["update_pbuilder_${name}"],
    content => $aptcontent,
  }

  file { "/usr/local/bin/pdebuild-${name}":
    ensure  => $ensure,
    mode    => 0775,
    content => "#!/bin/bash\n pdebuild --use-pdebuild-internal --configfile /etc/pbuilder/${name}/pbuilderrc --architecture ${arch}\n"
  }

  file { "/etc/pbuilder/${name}/hooks/F70aptupdate":
    ensure  => $ensure,
    mode    => 0775,
    content => template('debian/pbuilder_f70.erb')
  }

  # the result cache gets huge after a while - trim it to the last 7 days at 5am
  file { "/etc/cron.d/cleanup-${name}":
    ensure  => present,
    mode    => 0644,
    content => "11 5 * * * root find /var/cache/pbuilder/${name}/result -mtime +6 -delete\n"
  }

}
