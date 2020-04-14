define slave::pbuilder_setup (
  $arch,
  $release,
  $apturl,
  $aptcontent,
  $ensure     = present,
  $backports  = false,
  $nodesource = true,
  $puppetlabs = true,
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
    mode    => '0775',
    content => "#!/bin/bash\n pdebuild --use-pdebuild-internal --configfile /etc/pbuilder/${name}/pbuilderrc --architecture ${arch}\n",
  }

  file { "/etc/pbuilder/${name}/hooks/F70aptupdate":
    ensure  => $ensure,
    mode    => '0775',
    content => template('slave/pbuilder_f70.erb'),
  }

  # the result cache gets huge after a while - trim it to the last ~2 days at 5am
  file { "/etc/cron.d/cleanup-${name}":
    ensure  => file,
    mode    => '0644',
    content => "11 5 * * * root find /var/cache/pbuilder/${name}/result -mindepth 1 -mtime +1 -delete\n",
  }
}
