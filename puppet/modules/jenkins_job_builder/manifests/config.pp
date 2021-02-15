# Deploys a set of jobs to one Jenkins instance
#
define jenkins_job_builder::config (
  Stdlib::Httpurl $url,
  String $username,
  String $password,
  Integer[0] $jenkins_jobs_update_timeout = 600,
  String $command_arguments = 'jenkins-job-update',
  String $git_project_name = 'jenkins-jobs',
  String $git_repo = 'https://github.com/theforeman/jenkins-jobs.git',
  Optional[String] $git_ref = undef,
) {
  $config_name = $name
  $directory = '/etc/jenkins_jobs'
  $inifile = "${directory}/jenkins_jobs_${config_name}.ini"

  vcsrepo { "${directory}/${git_project_name}":
    ensure   => latest,
    provider => git,
    source   => $git_repo,
    revision => $git_ref,
    notify  => Exec["jenkins-jobs-update-${config_name}"],
  }

  exec { "jenkins-jobs-update-${config_name}":
    command => "jenkins-jobs --conf ${inifile} update ${directory}/${git_project_name}/${config_name} ${command_arguments}",
    timeout => $jenkins_jobs_update_timeout,
    path    => '/bin:/usr/bin:/usr/local/bin',
    require => File[$inifile],
  }

# TODO: We should put in  notify Exec['jenkins_jobs_update']
#       at some point, but that still has some problems.
  file { $inifile:
    ensure  => file,
    mode    => '0400',
    content => template('jenkins_job_builder/jenkins_jobs.ini.erb'),
  }
}
