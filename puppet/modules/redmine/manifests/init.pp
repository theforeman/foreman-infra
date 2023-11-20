# Hacky class to set up Redmine
# Needs VCS handling for cloning and bundling Redmine itself
#
# === Parameters:
#
# $secret_token::   Token used in the Rails initializer for session auth, etc
#
# $email_password:: Mailgun SMTP access password
#
# $app_root::       Directory holding the application
#
# $data_dir::       Directory containing the data
#
# $servername::     The DNS name to use as servername
#
# $repo_url::       The git repo URL to clone from
#
# $username::       User to run under
#
# $db_name::        Name of the database
#
# $db_password::    The password used to connect to redmine
#
# $https::          Whether to enable the https vhost
#
class redmine (
  String $secret_token           = 'token',
  String $email_password         = 'pass',
  Stdlib::Absolutepath $app_root = '/usr/share/redmine',
  Stdlib::Absolutepath $data_dir = '/var/lib/redmine',
  String $servername             = 'projects.theforeman.org',
  Stdlib::Httpsurl $repo_url     = 'https://github.com/theforeman/redmine',
  Optional[String] $repo_branch  = undef,
  String $username               = 'redmine',
  String $db_name                = 'redmine',
  String $db_password            = extlib::cache_data('foreman_cache_data', 'db_password', extlib::random_password(32)),
  Boolean $https                 = false,
  Boolean $cron                  = true,
) {
  # PostgreSQL tuning
  $postgresql_settings = {
    'checkpoint_completion_target' => '0.9',
    'effective_cache_size'         => '2GB',
    'shared_buffers'               => '512MB',
    'work_mem'                     => '4MB',
  }

  # Needed for bundle install
  $packages = [
    'git',
    'rubygem-bundler.noarch',
    'ruby-devel',
    'gcc',
    'gcc-c++',
    'libxml2-devel',
    'ImageMagick-devel',
    'postgresql-devel',
    'sqlite-devel',
    'redhat-rpm-config',
    'make',
  ]

  ensure_packages($packages)

  # Prevents errors if run from /root etc.
  Postgresql_psql {
    cwd => '/',
  }

  include postgresql::client, postgresql::server

  $postgresql_settings.each |$setting, $value| {
    postgresql::server::config_entry { $setting:
      value => $value,
    }
  }

  postgresql::server::db { $db_name:
    user     => $username,
    password => postgresql::postgresql_password($username, $db_password),
    owner    => $username,
    encoding => 'utf8',
    locale   => 'en_US.utf8',
  }

  # Create ident user for psql
  user { $username:
    ensure  => 'present',
    shell   => '/bin/false',
    comment => 'Redmine',
    home    => $app_root,
  }

  file { '/etc/redmine':
    ensure =>  directory,
  }

  file { '/etc/redmine/secure_config.yaml':
    ensure  => file,
    owner   => $username,
    group   => 'root',
    mode    => '0600',
    content => template('redmine/secure_config.yaml.erb'),
  }

  file { $app_root:
    ensure => directory,
    owner  => $username,
  }

  vcsrepo { $app_root:
    ensure   => present,
    provider => 'git',
    source   => $repo_url,
    revision => $repo_branch,
    owner    => $username,
    user     => $username,
    notify   => Exec['install redmine'],
  }

  # TODO: this should lay down a .bundle/config instead of using --path
  exec { 'install redmine':
    command     => 'bundle install --path ./vendor',
    user        => $username,
    cwd         => $app_root,
    path        => $::path,
    environment => ["HOME=${app_root}"],
    unless      => 'bundle check',
    require     => Package[$packages],
  }

  file { "${app_root}/config/database.yml":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('redmine/database.yml.erb'),
    require => Vcsrepo[$app_root],
  }

  file { $data_dir:
    ensure => directory,
    owner  => $username,
    group  => $username,
    mode   => '0750',
  }

  # Apache / Passenger

  include web::base

  $docroot          = "${app_root}/public"
  $priority         = '05'

  systemd::unit_file {'redmine.socket':
    ensure  => 'present',
    enable  => true,
    active  => true,
    content => file('redmine/redmine.socket'),
  }

  systemd::unit_file {'redmine.service':
    ensure  => 'present',
    enable  => true,
    active  => true,
    content => template('redmine/redmine.service.erb'),
  }

  $apache_backend_config = {
    'proxy_preserve_host' => true,
    'proxy_add_headers'   => true,
    'request_headers'     => ['set X_FORWARDED_PROTO "https"'],
    'proxy_pass'          => {
      'no_proxy_uris' => [
        '/server-status', '/help', '/images', '/javascripts', '/plugin_assets', '/stylesheets', '/themes', '/favicon.ico',
      ],
      'path'          => '/',
      'url'           => 'http://127.0.0.1:3000/',
    },
  }

  if $facts['os']['selinux']['enabled'] {
    selboolean { 'httpd_can_network_connect':
      persistent => true,
      value      => 'on',
    }
  }

  apache::vhost { $servername:
    docroot        => $docroot,
    manage_docroot => false,
    port           => 80,
    priority       => $priority,
    servername     => $servername,
    redirect_dest  => "https://${servername}/",
  }

  if $https {
    letsencrypt::certonly { $servername:
      plugin        => 'webroot',
      domains       => [$servername],
      webroot_paths => [$docroot],
      require       => Vcsrepo[$app_root],
    }

    apache::vhost { "${servername}-https":
      add_default_charset => 'UTF-8',
      docroot             => $docroot,
      manage_docroot      => false,
      port                => 443,
      options             => ['SymLinksIfOwnerMatch'],
      priority            => $priority,
      servername          => $servername,
      ssl                 => true,
      ssl_cert            => "/etc/letsencrypt/live/${servername}/fullchain.pem",
      ssl_chain           => "/etc/letsencrypt/live/${servername}/chain.pem",
      ssl_key             => "/etc/letsencrypt/live/${servername}/privkey.pem",
      headers             => [
        'set Strict-Transport-Security: max-age=15778800;',
      ],
      require             => [Letsencrypt::Certonly[$servername], Exec['install redmine']],
      *                   => $apache_backend_config,
    }
  }

  file { ["${app_root}/config.ru", "${app_root}/config/environment.rb"]:
    owner   => $username,
    require => Vcsrepo[$app_root],
  }

  # cron jobs ported from .openshift

  mailalias { $username:
    ensure    => present,
    recipient => 'sysadmins',
  }

  file { '/etc/cron.d/redmine':
    ensure  => bool2str($cron, 'file', 'absent'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('redmine/cron.erb'),
  }

  file { '/usr/local/bin/redmine_repos.sh':
    ensure  => bool2str($cron, 'file', 'absent'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file('redmine/git_repos.sh'),
  }

  # Logrotate
  file { '/etc/logrotate.d/redmine':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => file('redmine/logrotate'),
  }

}
