# @summary Set up the web vhost
# @api private
class web::vhost::web(
  String[1] $stable,
  String[1] $next,
  Boolean $setup_receiver = true,
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
  ]

  $docs_rewrites = [
    { 'rewrite_rule' => ["^/manuals/latest(.*) /manuals/${stable}\$1 [R,L]"] },
    { 'rewrite_rule' => ["^/manuals/${next}(.*) /manuals/nightly\$1 [R,L]"] },
    { 'rewrite_rule' => ["^/api/latest(.*) /api/${stable}\$1 [R,L]"] },
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
    servername    => 'theforeman.org',
    serveraliases => ['www.theforeman.org'],
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

  if $setup_receiver {
    secure_ssh::rsync::receiver_setup { 'web':
      user           => 'website',
      foreman_search => 'host ~ node*.jenkins.osuosl.theforeman.org and (name = external_ip4 or name = external_ip6)',
      script_content => file('web/rsync.sh'),
    }
  }
}
