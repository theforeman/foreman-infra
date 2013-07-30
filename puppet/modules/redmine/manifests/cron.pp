class redmine::cron {

  #  19 * * * * (cd ~/git/hammer-cli && git pull ) >/dev/null

  # Backups
  cron { 'redmine-backup':
    command => "(cd ${redmine::local_dir} && pg_dump ${redmine::db_name} > db/production.psqldump)",
    user    => $redmine::user,
    minute  => string_to_cron('redmine-backup'),
    hour    => string_to_cron('redmine-backup-hour', '24'),
  }

  # Sessions
  cron { 'redmine-sessions':
    command => "(cd ${redmine::local_dir} ; bundle exec rake tmp:sessions:clear)",
    user    => $redmine::user,
    minute  => string_to_cron('redmine-sessions-min'),
    hour    => string_to_cron('redmine-sessions-hour', '24'),
  }

  # $name is the redmine project identifier
  # $git_url is where to clone it from - --recurse-submodules is always done as well
  # $dirname is where to clone to - historically some projects have different checkouts
  # Once cloned, add /home/$redmine::user/git/$dirname to the project's settings in the UI
  $repos = {
    'foreman'        => { 'git_url' => 'https://github.com/theforeman/foreman.git',
                          'dirname' => 'foreman' },
    'smart-proxy'    => { 'git_url' => 'https://github.com/theforeman/smart-proxy.git',
                          'dirname' => 'smart-proxy' },
    'puppet-foreman' => { 'git_url' => 'https://github.com/theforeman/foreman-installer.git',
                          'dirname' => 'foreman-installer'},
    'rpms'           => { 'git_url' => 'https://github.com/theforeman/foreman-packaging',
                          'dirname' => 'foreman-rpms' },
    'discovery'      => { 'git_url' => 'https://github.com/theforeman/foreman_discovery',
                          'dirname' => 'foreman_discovery'},
    'content'        => { 'git_url' => 'https://github.com/theforeman/foreman_content',
                          'dirname' => 'foreman_content'},
    'selinux'        => { 'git_url' => 'https://github.com/theforeman/foreman-selinux',
                          'dirname' => 'foreman-selinux'},
    'hammer-cli'     => { 'git_url' => 'https://github.com/theforeman/hammer-cli',
                          'dirname' => 'hammer-cli'},
    'stacker'        => { 'git_url' => 'https://github.com/ohadlevy/stacker.git',
                          'dirname' => 'stacker' },
    'foreman_api'    => { 'git_url' => 'https://github.com/theforeman/foreman_api.git',
                          'dirname' => 'foreman_api' },
  }

  create_resources(redmine::repo,$repos)
}
