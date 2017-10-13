# Hacky class to set up Redmine
# Needs VCS handling for cloning and bundling Redmine itself
#
# === Parameters:
#
# $secret_token::   Token used in the Rails initializer for session auth, etc
#
# $email_password:: Mailgun SMTP access password
#
class redmine (
  String $secret_token   = 'token',
  String $email_password = 'pass',
) {
  $app_root    = '/usr/share/redmine'
  $db_name     = 'redmine4'
  $db_username = 'adminpz8bn8d'
  $db_password = cache_data('foreman_cache_data', 'db_password', random_password(32))
  $password    = postgresql_password($db_username, $db_password)

  # Prevents errors if run from /root etc.
  Postgresql_psql {
    cwd => '/',
  }

  include ::postgresql::client, ::postgresql::server

  postgresql::server::db { $db_name:
    user     => $db_username,
    password => $password,
    owner    => $db_username,
    encoding => 'utf8',
    locale   => 'en_US.utf8',
  }

  # Create ident user for psql
  user { $db_username:
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
    owner   => $db_username,
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

  include ::apache::mod::headers
  include ::apache::mod::passenger

  $servername       = 'projects.theforeman.org'
  $redmine_url      = "http://${servername}/"
  $docroot          = "${app_root}/public"
  $min_instances    = 1
  $start_timeout    = 600
  $priority         = '05'

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

  file { ["${app_root}/config.ru", "${app_root}/config/environment.rb"]:
    owner => $db_username,
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
    content => template('redmine/git_repos.sh'),
  }

  file { '/etc/cron.hourly/redmine_repos':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "#!/bin/bash
sudo -u ${db_username} /usr/local/bin/redmine_repos.sh",
  }

  # Logrotate
  file { '/etc/logrotate.d/redmine':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('redmine/logrotate.erb'),
  }

}
