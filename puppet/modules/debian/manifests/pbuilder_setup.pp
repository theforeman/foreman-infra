define debian::pbuilder_setup (
  $ensure  = present,
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

  file { "/etc/pbuilder/${name}/apt.config/debian.list":
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
    content => "#!/bin/sh

# F<digit><digit><whatever-else-you-want> is executed just before
# user logs in, or program starts executing, after chroot is created
# in --login or --execute target.

# Use local results of previous builds - not needed (yet)
#cd /var/cache/pbuilder/result/
#/usr/bin/dpkg-scanpackages . /dev/null >> /var/cache/pbuilder/result/Packages

# Update apt
/usr/bin/apt-get update\n"
  }


} 
