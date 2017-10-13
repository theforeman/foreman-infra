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
  Stdlib::Absolutepath $data_dir = '/var/lib/redmine_data',
  String $username               = 'redmine',
  String $db_name                = 'redmine',
  String $db_password            = cache_data('foreman_cache_data', 'db_password', random_password(32)),
  Boolean $https                 = false,
) {
  # Prevents errors if run from /root etc.
  Postgresql_psql {
    cwd => '/',
  }

  include ::postgresql::client, ::postgresql::server

  postgresql::server::db { $db_name:
    user     => $username,
    password => postgresql_password($username, $db_password),
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

  # TODO: handle cloning the redmine repo and bundle install...
  file { $app_root:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${app_root}/config/database.yml":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('redmine/database.yml.erb'),
  }

  file { $data_dir:
    ensure => directory,
    owner  => $username,
    group  => $username,
    mode   => '0750',
  }

  # Needed for bundle install
  $packages = [
    'rubygem-bundler.noarch',
    'ruby-devel',
    'gcc',
    'gcc-c++',
    'libxml2-devel',
    'ImageMagick-devel',
    'postgresql-devel',
    'sqlite-devel',
  ]

  ensure_packages($packages)

  # Apache / Passenger

  include ::web::base

  $servername       = 'projects.theforeman.org'
  $redmine_url      = "http://${servername}/"
  $docroot          = "${app_root}/public"
  $min_instances    = 1
  $start_timeout    = 600
  $priority         = '05'

  letsencrypt::certonly { $servername:
    plugin        => 'webroot',
    manage_cron   => false,
    domains       => [$servername],
    webroot_paths => [$docroot],
  }

  apache::vhost { $servername:
    add_default_charset     => 'UTF-8',
    docroot                 => $docroot,
    manage_docroot          => false,
    port                    => 80,
    options                 => ['SymLinksIfOwnerMatch'],
    passenger_app_root      => $app_root,
    passenger_min_instances => $min_instances,
    passenger_start_timeout => $start_timeout,
    priority                => $priority,
    servername              => $servername,
  }

  if $https {
    apache::vhost { "${servername}-https":
      add_default_charset     => 'UTF-8',
      docroot                 => $docroot,
      manage_docroot          => false,
      port                    => 443,
      options                 => ['SymLinksIfOwnerMatch'],
      passenger_app_root      => $app_root,
      passenger_min_instances => $min_instances,
      passenger_start_timeout => $start_timeout,
      priority                => $priority,
      servername              => $servername,
      ssl                     => true,
      ssl_cert                => "/etc/letsencrypt/live/${servername}/fullchain.pem",
      ssl_chain               => "/etc/letsencrypt/live/${servername}/chain.pem",
      ssl_key                 => "/etc/letsencrypt/live/${servername}/privkey.pem",
      require                 => Letsencrypt::Certonly[$servername],
    }
  }

  file { ["${app_root}/config.ru", "${app_root}/config/environment.rb"]:
    owner => $username,
  }

  # cron jobs ported from .openshift

  file { '/etc/cron.daily/redmine_backup':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('redmine/postgresql_backup.sh'),
  }

  file { '/usr/local/bin/redmine_repos.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file('redmine/git_repos.sh'),
  }

  file { '/etc/cron.hourly/redmine_repos':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "#!/bin/bash
sudo -u ${username} /usr/local/bin/redmine_repos.sh ${app_root} ${data_dir}",
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
