# Deploys a set of jobs to one Jenkins instance
#
define jenkins_job_builder::config (
  Stdlib::Httpurl $url,
  String $username,
  String $password,
  Integer[0] $jenkins_jobs_update_timeout = 600,
  String $git_project_name = 'foreman-infra',
  String $git_repo = 'https://github.com/theforeman/foreman-infra.git',
  String $git_branch = 'master',
  Optional[String] $git_args = undef,
  String $git_relative_path = 'jenkins-jobs',
) {
  $config_name = $name
  $directory = '/etc/jenkins_jobs'
  $inifile = "${directory}/jenkins_jobs_${config_name}.ini"

  file { "${directory}/${config_name}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    source  => "puppet:///modules/jenkins_job_builder/${config_name}",
    notify  => Exec["jenkins-jobs-update-${config_name}"],
  }

  git::repo { "jenkins-jobs-${config_name}":
    target => "${directory}/${git_project_name}",
    source => $git_repo,
    args   => $git_args,
  }

  exec { "jenkins-jobs-update-${config_name}":
    command => "jenkins-jobs --conf ${inifile} update ${directory}/${config_name} foreman-infra-jenkins-job-update",
    timeout => $jenkins_jobs_update_timeout,
    path    => '/bin:/usr/bin:/usr/local/bin',
    require => File[$inifile],
    cwd     => "${directory}/${git_project_name}/${git_relative_path}/${config_name}",
  }

# TODO: We should put in  notify Exec['jenkins_jobs_update']
#       at some point, but that still has some problems.
  file { $inifile:
    ensure  => file,
    mode    => '0400',
    content => template('jenkins_job_builder/jenkins_jobs.ini.erb'),
  }
}
