define pbuilder::cowbuilder (
  $ensure='present',
  $dist=$lsbdistcodename,
  $arch=$architecture,
  $cachedir='/var/cache/pbuilder',
  $confdir='/etc/pbuilder',
  $pbuilderrc=''
) {

  include concat::setup
  include pbuilder::cowbuilder::common

  $cowbuilder = '/usr/sbin/cowbuilder'
  $basepath = "${cachedir}/base-${name}.cow"

  concat {"${confdir}/${name}/apt/preferences":
    owner   => root,
    group   => root,
    mode    => '0644',
    force   => true,
    require => Package['pbuilder'],
  }

  case $ensure {
    present: {
      file {
        "${confdir}/${name}":
          ensure  => directory,
          require => Package['pbuilder'];

        "${confdir}/${name}/apt":
          ensure  => directory,
          require => File["${confdir}/${name}"];

        "${confdir}/${name}/apt/sources.list.d":
          ensure  => directory,
          recurse => true,
          purge   => true,
          force   => true,
          require => File["${confdir}/${name}/apt"];

        "${confdir}/${name}/pbuilderrc":
          ensure  => present,
          content => $pbuilderrc,
      }

      exec {
        "create cowbuilder ${name}":
          command => "${cowbuilder} --create --basepath ${basepath} --dist ${dist} --architecture ${arch}",
          require => File['/etc/pbuilderrc'],
          creates => $basepath;

        "update cowbuilder ${name}":
          command     => "${cowbuilder} --update --configfile ${confdir}/${name}/pbuilderrc --basepath ${basepath} --dist ${dist} --architecture ${arch} --override-config",
          refreshonly => true;
      }
    }

    absent: {
      file {
        "${confdir}/${name}":
          ensure => absent;

        $basepath:
          ensure => absent;
      }

    }

    default: {
      fail("Wrong value for ensure: ${ensure}")
    }
  }
  

}
