# @summary Set up the yum vhost
# @api private
class web::vhost::yum (
  String[1] $stable,
  Stdlib::Fqdn $servername = 'yum.theforeman.org',
  Stdlib::Absolutepath $yum_directory = '/var/www/vhosts/yum/htdocs',
  String $user = 'yumrepo',
) {
  include fastly_purge

  $yum_directory_config = [
    {
      path            => $yum_directory,
      options         => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      expires_active  => 'on',
      expires_default => 'access plus 2 minutes',
    },
    {
      path            => '.+\.(bz2|gz|rpm|xz)$',
      provider        => 'filesmatch',
      expires_active  => 'on',
      expires_default => 'access plus 30 days',
    },
    {
      path            => 'repomd.xml',
      provider        => 'files',
      expires_active  => 'on',
      expires_default => 'access plus 2 minutes',
    },
  ]

  secure_ssh::receiver_setup { $user:
    user           => $user,
    foreman_search => 'host ~ node*.jenkins.osuosl.theforeman.org and (name = external_ip4 or name = external_ip6)',
    script_content => file('web/deploy-yumrepo.sh'),
  }

  web::vhost { 'yum':
    servername    => "yum-backend.${facts['networking']['fqdn']}",
    docroot       => $yum_directory,
    docroot_owner => $user,
    docroot_group => $user,
    docroot_mode  => '0755',
    directories   => $yum_directory_config,
  }

  if $facts['os']['family'] == 'RedHat' {
    package { 'createrepo':
      ensure => present,
    }

    if $facts['os']['release']['major'] == '7' {
      yumrepo { 'pulpcore-3.16':
        descr    => 'pulpcore-3.16',
        baseurl  => "https://yum.theforeman.org/pulpcore/3.16/el${facts['os']['release']['major']}/x86_64/",
        enabled  => true,
        gpgcheck => true,
        gpgkey   => 'https://yum.theforeman.org/pulpcore/3.16/GPG-RPM-KEY-pulpcore',
        before   => Package['createrepo_c'],
      }
    }

    package { 'createrepo_c':
      ensure => present,
    }
  }

  file { "${yum_directory}/robots.txt":
    ensure  => file,
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => file('web/yum/robots.txt'),
  }

  file { "${yum_directory}/HEADER.html":
    ensure  => file,
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => epp("${module_name}/yum/HEADER.html.epp", { 'stable' => $stable }),
  }

  ['releases', 'plugins', 'client'].each |$directory| {
    file { ["${yum_directory}/${directory}", "${yum_directory}/${directory}/${stable}"]:
      ensure => directory,
      owner  => $user,
      group  => $user,
      mode   => '0755',
    }

    file { "${yum_directory}/${directory}/latest":
      ensure  => link,
      target  => $stable,
      require => File["${yum_directory}/${directory}/${stable}"],
      notify  => Exec["fastly-purge-${directory}-latest"],
    }

    exec { "fastly-purge-${directory}-latest":
      command     => "fastly-purge-find 'https://${servername}' ${yum_directory} ${directory}/latest/",
      path        => '/bin:/usr/bin:/usr/local/bin',
      require     => File['/usr/local/bin/fastly-purge-find'],
      refreshonly => true,
    }
  }

  file { "${yum_directory}/latest":
    ensure  => link,
    target  => 'releases/latest',
    require => File["${yum_directory}/releases/latest"],
  }

  exec { 'fastly-purge-root-latest':
    command     => "fastly-purge-find 'https://${servername}' ${yum_directory} latest/",
    path        => '/bin:/usr/bin:/usr/local/bin',
    require     => File['/usr/local/bin/fastly-purge-find', "${yum_directory}/latest"],
    subscribe   => File["${yum_directory}/releases/latest"],
    refreshonly => true,
  }

  file { "${yum_directory}/releases/nightly":
    ensure => link,
    target => '../nightly',
  }

  file { "${yum_directory}/pulpcore":
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => '0755',
  }

  file { "${yum_directory}/pulpcore/HEADER.html":
    ensure  => file,
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => file('web/yum/pulpcore-HEADER.html'),
  }
}
