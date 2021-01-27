define slave::pbuilder_setup (
  $arch,
  $release,
  $apturl,
  $aptcontent,
  $ensure     = present,
  Boolean $backports  = false,
  Boolean $nodesource = true,
  Boolean $puppetlabs = true,
  Enum['pbuilder', 'cowbuilder'] $pbuilder_type = 'pbuilder',
) {

  case $pbuilder_type {
    'pbuilder': {
      pbuilder { $name:
        ensure    => $ensure,
        arch      => $arch,
        release   => $release,
        methodurl => $apturl,
      }
      $update_pbuilder = "update_pbuilder_${name}"
    }
    'cowbuilder': {
      pbuilder::cowbuilder { $name:
        ensure  => $ensure,
        arch    => $arch,
        release => $release,
      }
      $update_pbuilder = "update cowbuilder ${name}"
    }
    default: {
      # Unreachable due to the data type
    }
  }

  file { "/etc/pbuilder/${name}/apt.config/sources.list.d/debian.list":
    ensure  => $ensure,
    content => $aptcontent,
  }
  if $ensure == present {
    File["/etc/pbuilder/${name}/apt.config/sources.list.d/debian.list"] ~> Exec[$update_pbuilder]
  }

  file { "/usr/local/bin/pdebuild-${name}":
    ensure  => $ensure,
    mode    => '0775',
    content => template('slave/pbuilder_pdebuild.erb'),
  }

  $hooks = {
    'C10foremanlog'            => true,
    'D80no-man-db-rebuild'     => true,
    'F60addforemanrepo'        => true,
    'F65-add-backport-repos'   => $backports,
    'F66-add-nodesource-repos' => $nodesource,
    'F67-add-puppet-repos'     => $puppetlabs,
    'F70aptupdate'             => true,
    'F99printrepos'            => true,
  }

  $hooks.each |$hook, $enabled| {
    $hook_path = "/etc/pbuilder/${name}/hooks/${hook}"
    if $enabled {
      file { $hook_path:
        ensure  => $ensure,
        mode    => '0775',
        content => file("slave/pbuilder_${hook}"),
      }
    } else {
      file { $hook_path:
        ensure => absent,
      }
    }
  }

  # the result cache gets huge after a while - trim it to the last ~2 days at 5am
  file { "/etc/cron.d/cleanup-${name}":
    ensure  => bool2str($ensure == present, 'file', 'absent'),
    mode    => '0644',
    content => "11 5 * * * root find /var/cache/pbuilder/${name}/result -mindepth 1 -mtime +1 -delete\n",
  }

  file { "/etc/cron.d/update-${name}":
    ensure  => bool2str($ensure == present, 'file', 'absent'),
    mode    => '0644',
    content => "11 4 * * * root /usr/local/bin/pbuilder-${name} update\n",
  }
}
