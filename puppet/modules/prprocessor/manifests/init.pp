# Class to set up the PR processor
#
# @param github_oauth_token The Github oauth token
# @param github_secret_token The github secret token
# @param redmine_api_key The API key for Redmine
# @param jenkins_token The token to use for the Jenkins API
# @param sentry_dsn The Sentry DSN
# @param username The unix username the PR processor should run as
# @param servername The DNS name to use as servername
# @param repo_url The git repo URL to clone from
# @param app_root The path on the filesystem to clone to
# @param https Whether to run on HTTPS besides HTTP
class prprocessor (
  String $github_oauth_token,
  String $github_secret_token,
  String $redmine_api_key,
  String $jenkins_token,
  String $sentry_dsn,
  String $username               = 'prprocessor',
  String $servername             = 'prprocessor.theforeman.org',
  Stdlib::Httpsurl $repo_url     = 'https://github.com/theforeman/prprocessor.git',
  Stdlib::Absolutepath $app_root = '/usr/share/prprocessor',
  Boolean $https                 = false,
) {

  user { $username:
    ensure => 'present',
    shell  => '/bin/false',
    home   => $app_root,
  }

  file { $app_root:
    ensure => directory,
    owner  => $username,
    group  => $username,
  }

  # Needed for bundle install
  $packages = [
    'gcc',
    'make',
    'ruby-devel',
    'rubygem-bundler',
  ]

  ensure_packages($packages)

  # App install

  vcsrepo { $app_root:
    ensure   => present,
    provider => 'git',
    source   => $repo_url,
    user     => $username,
    require  => File[$app_root],
    notify   => Exec['install prprocessor'],
  }

  exec { 'install prprocessor':
    command     => 'bundle install',
    user        => $username,
    cwd         => $app_root,
    path        => $::path,
    environment => ["HOME=${app_root}"],
    unless      => 'bundle check',
    require     => Package[$packages],
  }

  # Cron

  mailalias { $username:
    ensure    => present,
    recipient => 'sysadmins',
  }

  cron { 'close inactive':
    command     => "cd ${app_root} && bundle exec scripts/close_inactive.rb",
    user        => $username,
    environment => [
      "HOME=${app_root}",
      "GITHUB_OAUTH_TOKEN='${github_oauth_token}'",
      "REDMINE_API_KEY='${redmine_api_key}'",
    ],
    hour        => 1,
    minute      => 23,
    require     => Exec['install prprocessor'],
  }

  # Apache / Passenger

  include ::web::base

  $docroot = '/var/www/html'
  $env = [
    "GITHUB_OAUTH_TOKEN ${github_oauth_token}",
    "GITHUB_SECRET_TOKEN ${github_secret_token}",
    "REDMINE_API_KEY ${redmine_api_key}",
    "JENKINS_TOKEN ${jenkins_token}",
    "SENTRY_DSN ${sentry_dsn}",
  ]

  letsencrypt::certonly { $servername:
    plugin        => 'webroot',
    domains       => [$servername],
    webroot_paths => [$docroot],
    require       => Apache::Vhost[$servername],
  }

  apache::vhost { $servername:
    add_default_charset => 'UTF-8',
    docroot             => $docroot,
    manage_docroot      => false,
    port                => 80,
    options             => [],
    passenger_app_root  => $app_root,
    servername          => $servername,
    setenv              => $env,
    require             => Exec['install prprocessor'],
  }

  if $https {
    apache::vhost { "${servername}-https":
      add_default_charset => 'UTF-8',
      docroot             => $docroot,
      manage_docroot      => false,
      port                => 443,
      options             => [],
      passenger_app_root  => $app_root,
      servername          => $servername,
      setenv              => $env,
      ssl                 => true,
      ssl_cert            => "/etc/letsencrypt/live/${servername}/fullchain.pem",
      ssl_chain           => "/etc/letsencrypt/live/${servername}/chain.pem",
      ssl_key             => "/etc/letsencrypt/live/${servername}/privkey.pem",
      require             => [Letsencrypt::Certonly[$servername], Exec['install prprocessor']],
    }
  }
}
