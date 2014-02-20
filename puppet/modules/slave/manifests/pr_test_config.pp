define slave::pr_test_config($ensure = 'present') {
  file { "/home/jenkins/test_pull_request_${name}_not_mergable":
    ensure => $ensure,
    owner  => "jenkins",
    group  => "jenkins",
  }

  if $::slave::github_user and $::slave::github_oauth and $::slave::jenkins_build_token {
    $github_user = $::slave::github_user
    $github_oauth = $::slave::github_oauth
    $jenkins_build_token = $::slave::jenkins_build_token

    file { "/home/jenkins/.test_pull_requests_${name}.json":
      ensure  => $ensure,
      owner   => "jenkins",
      group   => "jenkins",
      content => template("slave/test_pull_requests_${name}.json.erb"),
      require => File['/var/lib/workspace']
    }
  }
}
