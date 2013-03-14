define redmine::plugin(
  $git_url,
  $plugin_dir = "${redmine::local_dir}/plugins",
  $user       = $redmine::user,
) {

  git::repo {$name:
    target  => "${plugin_dir}/${name}",
    source  => $git_url,
    notify  => Exec['rails_plugin_migrations'],
    require => Class['install'],
  }

  exec { 'rails_plugin_migrations':
    environment => ["HOME=${redmine::local_dir}","RAILS_ENV=${redmine::environment}",'REDMINE_LANG=en'],
    command     => 'bundle exec rake redmine:plugins:migrate',
    require     => Exec['rails_migrations'],
    before      => Service['apache'],
    refreshonly => true,
    user        => $user,
    cwd         => $redmine::local_dir,
  }

}