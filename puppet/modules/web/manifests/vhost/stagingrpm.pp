# @summary Set up the rpm staging vhost
# @api private
class web::vhost::stagingrpm (
  Array[String[1]] $usernames = [],
  Stdlib::Fqdn $servername = 'stagingrpm.theforeman.org',
  Stdlib::Absolutepath $rpm_staging_directory = '/var/www/vhosts/stagingrpm/htdocs',
  String $user = 'rpmrepostage',
  Stdlib::Absolutepath $home = "/home/${user}",
) {
  $rpm_staging_directory_config = [
    {
      path            => $rpm_staging_directory,
      options         => ['Indexes', 'FollowSymLinks'],
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

  include apache::mod::alias
  include apache::mod::autoindex
  include apache::mod::dir
  include apache::mod::expires
  include apache::mod::mime

  $authorized_keys = flatten($usernames.map |$name| {
    split(file("users/${name}-authorized_keys"), "\n")
  })

  secure_ssh::rsync::receiver_setup { $user:
    ensure          => 'absent',
    user            => $user,
    homedir         => $home,
    homedir_mode    => '0750',
    foreman_search  => 'host ~ node*.jenkins.*.theforeman.org and (name = external_ip4 or name = external_ip6)',
    authorized_keys => $authorized_keys,
    script_content  => epp("${module_name}/deploy-stagingrpm.sh.epp", {
      'home'                  => $home,
      'rpm_staging_directory' => $rpm_staging_directory,
    }),
  }

  web::vhost { 'stagingrpm':
    ensure        => 'absent',
    servername    => "stagingrpm-backend.${facts['networking']['fqdn']}",
    docroot       => $rpm_staging_directory,
    docroot_owner => $user,
    docroot_group => $user,
    docroot_mode  => '0755',
    directories   => $rpm_staging_directory_config,
  }

  file { "${rpm_staging_directory}/robots.txt":
    ensure  => 'absent',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => file('web/stagingrpm/robots.txt'),
  }

  file { "${rpm_staging_directory}/HEADER.html":
    ensure  => 'absent',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp("${module_name}/stagingrpm/HEADER.html.epp", {
      'servername' => $servername,
    }),
  }

  ['candlepin', 'foreman', 'pulpcore'].each |$directory| {
    file { ["${rpm_staging_directory}/${directory}"]:
      ensure => 'absent',
      owner  => $user,
      group  => $user,
      mode   => '0755',
    }
  }
}
