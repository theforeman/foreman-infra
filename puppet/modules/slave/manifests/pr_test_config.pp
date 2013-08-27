define slave::pr_test_config($not_mergable_cache = undef) {
  $not_mergable_cache_path = $not_mergable_cache ? {
    undef   => "/home/jenkins/test_pull_request_${name}_not_mergable",
    default => $not_mergable_cache,
  }

  file { $not_mergable_cache_path:
    ensure => file,
    owner  => "jenkins",
    group  => "jenkins",
  }

  if $github_user and $github_oauth and $jenkins_build_token {
    file { "/home/jenkins/.test_pull_requests_${name}.json":
      ensure  => file,
      owner   => "jenkins",
      group   => "jenkins",
      content => template("slave/test_pull_requests_${name}.json.erb"),
      require => File['/var/lib/workspace']
    }
  }
}
