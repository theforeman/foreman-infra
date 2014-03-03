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

  # $name is where to clone to - historically some projects have different checkouts
  # $git_url is where to clone it from - --recurse-submodules is always done as well
  # $project_name is the redmine project identifier
  # Once cloned, add /home/$redmine::user/git/$name to the project's settings in the UI
  $repos = {
    'foreman'                   => { 'git_url' => 'https://github.com/theforeman/foreman.git',
                                     'project_name' => 'foreman' },
    'smart-proxy'               => { 'git_url' => 'https://github.com/theforeman/smart-proxy.git',
                                     'project_name' => 'smart-proxy' },
    'foreman-rpms'              => { 'git_url' => 'https://github.com/theforeman/foreman-packaging',
                                     'project_name' => 'rpms' },
    'foreman-selinux'           => { 'git_url' => 'https://github.com/theforeman/foreman-selinux',
                                     'project_name' => 'selinux'},
    # installer
    'foreman-installer'         => { 'git_url' => 'https://github.com/theforeman/foreman-installer.git',
                                     'project_name' => 'puppet-foreman'},
    'puppet-foreman'            => { 'git_url' => 'https://github.com/theforeman/puppet-foreman.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-foreman'},
    'puppet-foreman_proxy'      => { 'git_url' => 'https://github.com/theforeman/puppet-foreman_proxy.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-foreman_proxy'},
    'kafo'                      => { 'git_url' => 'https://github.com/theforeman/kafo.git',
                                     'project_name' => 'kafo'},
    # CLI etc.
    'foreman_api'               => { 'git_url' => 'https://github.com/theforeman/foreman_api.git',
                                     'project_name' => 'foreman',
                                     'subrepo_id' => 'foreman_api'},
    'hammer-cli'                => { 'git_url' => 'https://github.com/theforeman/hammer-cli',
                                     'project_name' => 'foreman',
                                     'subrepo_id' => 'hammer-cli'},
    'hammer-cli-foreman'        => { 'git_url' => 'https://github.com/theforeman/hammer-cli-foreman',
                                     'project_name' => 'foreman',
                                     'subrepo_id' => 'hammer-cli-foreman'},
    'hammer-cli-katello-bridge' => { 'git_url' => 'https://github.com/theforeman/hammer-cli-katello-bridge',
                                     'project_name' => 'foreman',
                                     'subrepo_id' => 'hammer-cli-katello-bridge'},
    # plugins
    'foreman_content'           => { 'git_url' => 'https://github.com/theforeman/foreman_content',
                                     'project_name' => 'content'},
    'foreman_discovery'         => { 'git_url' => 'https://github.com/theforeman/foreman_discovery',
                                     'project_name' => 'discovery'},
    'stacker'                   => { 'git_url' => 'https://github.com/ohadlevy/stacker.git',
                                     'project_name' => 'stacker' },
    'katello'                   => { 'git_url' => 'https://github.com/Katello/katello.git',
                                     'project_name' => 'katello' },
    'ofi'                       => { 'git_url' => 'https://github.com/theforeman/ofi.git',
                                     'project_name' => 'ofi' },
  }

  create_resources(redmine::repo,$repos)
}
