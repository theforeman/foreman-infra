define slave::pr_test_config($ensure = 'present') {
  file { "/home/jenkins/pr_tests/cache/test_pull_request_${name}_not_mergable":
    ensure => $ensure,
    owner  => "jenkins",
    group  => "jenkins",
  }

  if $::slave::github_user and $::slave::github_oauth and $::slave::jenkins_build_token {
    $github_user = $::slave::github_user
    $github_oauth = $::slave::github_oauth
    $jenkins_build_token = $::slave::jenkins_build_token

    $json_content = $ensure ? {
      present => template("slave/test_pull_requests_${name}.json.erb"),
      default => undef,
    }
    file { "/home/jenkins/pr_tests/test_pull_requests_${name}.json":
      ensure  => $ensure,
      owner   => "jenkins",
      group   => "jenkins",
      content => $json_content,
      require => File['/var/lib/workspace']
    }
  }
}
