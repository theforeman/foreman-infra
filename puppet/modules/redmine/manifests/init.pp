class redmine(
  $site_name     = 'redmine.example.com',
  $upstream_repo = 'https://github.com/redmine/redmine',
  $local_dir     = '/srv/redmine',
  $user          = 'redmine',
  $user_home     = '/home/redmine',
  $db_adapter    = 'postgresql',
  $db_name       = 'redmine',
  $db_password   = 'UNSET',
  $environment   = 'production',
  $site_aliases  = ["${::hostname}"],
  $smtp_server   = '127.0.0.1',
  $smtp_port     = 25,
  $smtp_domain   = 'example.com',
) {

  $db_password_real = $db_password ? {
    'UNSET' => cache_data('redmine_password', random_password(32)),
    default => $db_password,
  }

  include 'install', 'config'
  Class['install'] -> Class['config']
}
