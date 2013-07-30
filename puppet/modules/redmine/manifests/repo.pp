define redmine::repo(
  $git_url
  $dirname
) {

  include git

  cron { "redmine-sync-cron-${name}":
    command => "(cd ~/git/${dirname} && git pull --recurse-submodules && curl http://projects.theforeman.org/projects/${name}/repository ) > /dev/null",
    user    => $redmine::user,
    minute  => string_to_cron($name,60),
  }

  git::repo { "redmine-git-${name}":
    target => "/home/${redmine::user}/git/${dirname}",
    source => $git_url,
    user   => $redmine::user,
  }
}
