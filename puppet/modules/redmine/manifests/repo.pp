define redmine::repo(
  $git_url,
  $project_name,
  $subrepo_id = undef,
) {

  include git

  if $subrepo_id {
    $url = "http://projects.theforeman.org/projects/${project_name}/repository/${subrepo_id}"
  } else {
    $url = "http://projects.theforeman.org/projects/${project_name}/repository"
  }

  cron { "redmine-sync-cron-${name}":
    command => "(cd ~/git/${name} && git pull -q && curl -sS ${url} ) > /dev/null",
    user    => $redmine::user,
    minute  => string_to_cron($name,60),
  }

  git::repo { "redmine-git-${name}":
    target => "/home/${redmine::user}/git/${name}",
    source => $git_url,
    user   => $redmine::user,
  }
}
