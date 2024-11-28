# @summary Set up the web vhost
# @api private
class web::vhost::web(
  String[1] $stable,
  Stdlib::Absolutepath $web_directory = '/var/www/vhosts/web/htdocs',
) {
  require web

  if $web::https {
    $https_rewrites = [
      {
        'rewrite_cond' => ['%{HTTPS} !=on'],
        'rewrite_rule' => ['^/?(.*) https://%{SERVER_NAME}/$1 [R=301,L]'],
      },
    ]
  } else {
    $https_rewrites = []
  }

  $external_rewrites = [
    { 'rewrite_rule' => ['^/projects(.*)  https://projects.theforeman.org/projects$1  [R,L]'] },
    { 'rewrite_rule' => ['^/issues(.*)  https://projects.theforeman.org/issues$1  [R,L]'] },
    { 'rewrite_rule' => ['^/versions(.*)  https://projects.theforeman.org/versions$1  [R,L]'] },
    { 'rewrite_rule' => ['^/wiki(.*)  https://projects.theforeman.org/wiki$1  [R,L]'] },
    { 'rewrite_rule' => ['^/events/all.ics https://community.theforeman.org/c/events/l/calendar.ics [R,L]'] },
    { 'rewrite_rule' => ['^/events/? https://community.theforeman.org/c/events/l/calendar [R,L]'] },
    { 'rewrite_rule' => ["^/api/latest(.*) https://apidocs.theforeman.org/foreman/${stable}\$1 [R,L]"] },
    { 'rewrite_rule' => ['^/api/(.*) https://apidocs.theforeman.org/foreman/$1 [R,L]'] },
    { 'rewrite_rule' => ['^/api$ https://apidocs.theforeman.org/foreman/ [R,L]'] },
  ]

  $docs_rewrites = [
    { 'rewrite_rule' => ["^/manuals/latest(.*) /manuals/${stable}\$1 [R,L]"] },
  ]

  $directory_config = [
    {
      path            => $web_directory,
      options         => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      expires_active  => 'on',
      expires_default => 'access plus 2 hours',
    },
    {
      path            => "${web_directory}/static",
      expires_active  => 'on',
      expires_default => 'access plus 30 days',
    },
    {
      path            => 'feed.xml',
      provider        => 'files',
      expires_active  => 'on',
      expires_default => 'access plus 30 minutes',
    },
    {
      path            => '/(manuals|api)/latest',
      provider        => 'locationmatch',
      expires_active  => 'on',
      expires_default => 'access plus 30 minutes',
    },
    {
      path            => '/blog',
      provider        => 'location',
      expires_active  => 'on',
      expires_default => 'access plus 30 minutes',
    },
  ]

  web::vhost { 'web':
    servername    => "web-backend.${facts['networking']['fqdn']}",
    serveraliases => ['theforeman.org', 'www.theforeman.org'],
    directories   => $directory_config,
    docroot       => $web_directory,
    docroot_owner => 'website',
    docroot_group => 'website',
    docroot_mode  => '0755',
    attrs         => {
      'rewrites'        => $external_rewrites + $https_rewrites + $docs_rewrites,
      'error_documents' => [ { 'error_code' => 404, 'document' => '/404.html' } ],
    },
  }

  # vhosts don't autorequire the expires module
  # https://github.com/puppetlabs/puppetlabs-apache/pull/2559
  # limit to not EL7 as there we use apache::default_mods
  if $facts['os']['family'] != 'RedHat' or $facts['os']['release']['major'] != '7' {
    include apache::mod::expires
  }
  include apache::mod::dir
  include apache::mod::autoindex
  include apache::mod::alias
  include apache::mod::mime

  secure_ssh::rsync::receiver_setup { 'web':
    user           => 'website',
    foreman_search => 'host ~ node*.jenkins.osuosl.theforeman.org and (name = external_ip4 or name = external_ip6)',
    script_content => file('web/rsync.sh'),
  }

  # Generate RSS stats
  file { '/var/log/rss-stat':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  file { '/etc/cron.weekly/rss-stat':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file('web/rss-stat.sh'),
  }
}
