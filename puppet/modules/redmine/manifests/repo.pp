define redmine::repo(
  $git_url,
  $project_name
) {

  include git

  cron { "redmine-sync-cron-${name}":
    command => "(cd ~/git/${name} && git pull -q && curl -sS http://projects.theforeman.org/projects/${project_name}/repository ) > /dev/null",
    user    => $redmine::user,
    minute  => string_to_cron($name,60),
  }

  git::repo { "redmine-git-${name}":
    target => "/home/${redmine::user}/git/${name}",
    source => $git_url,
    user   => $redmine::user,
  }
}
