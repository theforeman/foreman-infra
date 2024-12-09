# @summary Set up the rpm vhost
# @api private
class web::vhost::rpm (
  String[1] $stable_foreman,
  Stdlib::Fqdn $servername = 'rpm.theforeman.org',
  Stdlib::Absolutepath $rpm_directory = '/var/www/vhosts/rpm/htdocs',
  Stdlib::Absolutepath $rpm_staging_directory = '/var/www/vhosts/stagingrpm/htdocs/',
  String $user = 'rpmrepo',
) {
  include fastly_purge

  $rpm_directory_config = [
    {
      path            => $rpm_directory,
      options         => ['+Indexes', '+FollowSymLinks'],
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

  $deploy_rpmrepo_context = {
    'servername'           => $servername,
    'rpm_directory'        => $rpm_directory,
    'rpm_staging_directory' => $rpm_staging_directory,
  }

  secure_ssh::receiver_setup { $user:
    user           => $user,
    foreman_search => 'host ~ node*.jenkins.osuosl.theforeman.org and (name = external_ip4 or name = external_ip6)',
    script_content => epp('web/deploy-rpmrepo.sh.epp', $deploy_rpmrepo_context),
  }

  include apache::mod::expires
  include apache::mod::dir
  include apache::mod::autoindex
  include apache::mod::alias
  include apache::mod::mime

  web::vhost { 'rpm':
    servername    => "rpm-backend.${facts['networking']['fqdn']}",
    docroot       => $rpm_directory,
    docroot_owner => $user,
    docroot_group => $user,
    docroot_mode  => '0755',
    directories   => $rpm_directory_config,
  }

  if $facts['os']['family'] == 'RedHat' {
    package { 'createrepo_c':
      ensure => present,
    }
  }

  file { "${rpm_directory}/robots.txt":
    ensure  => file,
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => file('web/rpm/robots.txt'),
  }

  file { "${rpm_directory}/HEADER.html":
    ensure  => file,
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => epp("${module_name}/rpm/HEADER.html.epp", {
        'stable_foreman' => $stable_foreman,
        'servername'     => $servername,
    }),
  }

  ['candlepin', 'foreman', 'pulpcore'].each |$directory| {
    file { ["${rpm_directory}/${directory}"]:
      ensure => directory,
      owner  => $user,
      group  => $user,
      mode   => '0755',
    }

    exec { "fastly-purge-${directory}-latest":
      command     => "fastly-purge-find 'https://${servername}' ${rpm_directory} ${directory}/latest/",
      path        => '/bin:/usr/bin:/usr/local/bin',
      require     => File['/usr/local/bin/fastly-purge-find'],
      refreshonly => true,
    }
  }

  file { "${rpm_directory}/pulpcore/HEADER.html":
    ensure  => file,
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => file('web/rpm/pulpcore-HEADER.html'),
  }
}
