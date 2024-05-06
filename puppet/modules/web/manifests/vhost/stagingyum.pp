# @summary Set up the yum vhost
# @api private
class web::vhost::stagingyum (
  Stdlib::Fqdn $servername = 'stagingyum.theforeman.org',
  Stdlib::Absolutepath $yum_directory = '/var/www/vhosts/stagingyum/htdocs',
  String $user = 'yumrepostage',
  Stdlib::Absolutepath $home = "/home/${user}",
  Array[String[1]] $usernames = ['ehelms', 'evgeni', 'ekohl', 'Odilhao', 'pcreech', 'zhunting'],
) {
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

  $authorized_keys = flatten($usernames.map |$name| {
      split(file("users/${name}-authorized_keys"), "\n")
  })

  secure_ssh::rsync::receiver_setup { $user:
    user            => $user,
    homedir         => $home,
    homedir_mode    => '0750',
    foreman_search  => 'host ~ node*.jenkins.*.theforeman.org and (name = external_ip4 or name = external_ip6)',
    script_content  => template('web/deploy-stagingyum.sh.erb'),
    authorized_keys => $authorized_keys,
  }

  web::vhost { 'stagingyum':
    servername    => $servername,
    docroot       => $yum_directory,
    docroot_owner => $user,
    docroot_group => $user,
    docroot_mode  => '0755',
    directories   => $yum_directory_config,
  }

  ['HEADER.html', 'robots.txt'].each |$filename| {
    file { "${yum_directory}/${filename}":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => file("web/stagingyum/${filename}"),
    }
  }
}
