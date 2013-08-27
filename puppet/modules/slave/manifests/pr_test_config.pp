define slave::pr_test_config() {
  file { "/home/jenkins/test_pull_request_${name}_not_mergable",
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
