class redmine(
  $site_name     = 'redmine.example.com',
  $upstream_repo = 'https://github.com/redmine/redmine',
  $local_dir     = '/tmp/redmine',
  $user          = 'redmine',
  $user_home     = '/home/redmine',
  $db_adapter    = 'sqlite',
  $environment   = 'production',
  $site_aliases  = [],
  $smtp_server   = '127.0.0.1',
  $smtp_port     = 25,
  $smtp_domain   = 'example.com',
) {
  include 'install', 'config'
  Class['install'] -> Class['config']
}
