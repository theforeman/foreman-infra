class redmine::cron {

  #  19 * * * * (cd ~/git/hammer-cli && git pull ) >/dev/null

  # Backups
  cron { 'redmine-backup':
    command => "(cd ${redmine::local_dir} && pg_dump ${redmine::db_name} > db/production.psqldump && gzip -9f db/production.psqldump)",
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
    'puppet-concat'             => { 'git_url' => 'https://github.com/theforeman/puppet-concat.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-concat'},
    'puppet-dhcp'               => { 'git_url' => 'https://github.com/theforeman/puppet-dhcp.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-dhcp'},
    'puppet-dns'                => { 'git_url' => 'https://github.com/theforeman/puppet-dns.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-dns'},
    'puppet-foreman'            => { 'git_url' => 'https://github.com/theforeman/puppet-foreman.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-foreman'},
    'puppet-foreman_proxy'      => { 'git_url' => 'https://github.com/theforeman/puppet-foreman_proxy.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-foreman_proxy'},
    'puppet-git'                => { 'git_url' => 'https://github.com/theforeman/puppet-git.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-git'},
    'puppet-puppet'             => { 'git_url' => 'https://github.com/theforeman/puppet-puppet.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-puppet'},
    'puppet-tftp'               => { 'git_url' => 'https://github.com/theforeman/puppet-tftp.git',
                                     'project_name' => 'puppet-foreman',
                                     'subrepo_id' => 'puppet-tftp'},
    'kafo'                      => { 'git_url' => 'https://github.com/theforeman/kafo.git',
                                     'project_name' => 'kafo'},
    # CLI etc.
    'foreman_api'               => { 'git_url' => 'https://github.com/theforeman/foreman_api.git',
                                     'project_name' => 'foreman',
                                     'subrepo_id' => 'foreman_api'},
    'hammer-cli'                => { 'git_url' => 'https://github.com/theforeman/hammer-cli',
                                     'project_name' => 'hammer-cli'},
    'hammer-cli-foreman'        => { 'git_url' => 'https://github.com/theforeman/hammer-cli-foreman',
                                     'project_name' => 'hammer-cli',
                                     'subrepo_id' => 'hammer-cli-foreman'},
    # plugins
    'foreman_content'           => { 'git_url' => 'https://github.com/theforeman/foreman_content',
                                     'project_name' => 'content'},
    'foreman_discovery'         => { 'git_url' => 'https://github.com/theforeman/foreman_discovery',
                                     'project_name' => 'discovery'},
    'foreman_snapshot'          => { 'git_url' => 'https://github.com/theforeman/foreman_snapshot',
                                     'project_name' => 'snapshot'},
    'stacker'                   => { 'git_url' => 'https://github.com/ohadlevy/stacker.git',
                                     'project_name' => 'stacker' },
    'ofi'                       => { 'git_url' => 'https://github.com/theforeman/ofi.git',
                                     'project_name' => 'ofi' },
    'hammer-cli-foreman-tasks'  => { 'git_url' => 'https://github.com/inecas/hammer-cli-foreman-tasks.git',
                                     'project_name' => 'foreman-tasks' },
    # katello plugin
    'katello'                   => { 'git_url' => 'https://github.com/Katello/katello.git',
                                     'project_name' => 'katello' },
    'hammer-cli-katello'        => { 'git_url' => 'https://github.com/Katello/hammer-cli-katello.git',
                                     'project_name' => 'katello',
                                     'subrepo_id' => 'hammer-cli-katello' },
    'katello-installer'         => { 'git_url' => 'https://github.com/Katello/katello-installer.git',
                                     'project_name' => 'katello',
                                     'subrepo_id' => 'katello-installer' },
    'hammer-cli-csv'            => { 'git_url' => 'https://github.com/Katello/hammer-cli-csv.git',
                                     'project_name' => 'katello',
                                     'subrepo_id' => 'hammer-cli-csv' },
  }

  create_resources(redmine::repo,$repos)
}
