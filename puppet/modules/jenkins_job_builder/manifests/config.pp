# Deploys a set of jobs to one Jenkins instance
#
# $run is our addition and is so named becuase noop is a bit too magic in puppet syntax...
#
define jenkins_job_builder::config (
  $url,
  $username,
  $password,
  $run = 'false',
  $jenkins_jobs_update_timeout = '600',
) {
  $config_name = $name
  $inifile = "/etc/jenkins_jobs/jenkins_jobs_${config_name}.ini"

  file { "/etc/jenkins_jobs/${config_name}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    source  => "puppet:///modules/jenkins_job_builder/${config_name}",
    notify  => Exec["jenkins_jobs_update-${config_name}"],
  }

  # test for a string here since it's annoyingly hard to pass a boolean from foreman via yaml
  if $run == 'false' {
    $subcmd = 'test'
  } else {
    $subcmd = 'update --delete-old'
  }
  $cmd = "jenkins-jobs --conf ${inifile} ${subcmd} /etc/jenkins_jobs/${config_name} > /var/cache/jjb.xml"

  exec { "jenkins_jobs_update-${config_name}":
    command     => $cmd,
    timeout     => $jenkins_jobs_update_timeout,
    path        => '/bin:/usr/bin:/usr/local/bin',
    refreshonly => true,
    require     => [ File[$inifile], Exec["remove_unmanaged_jobs-${config_name}"] ],
  }

  exec { "remove_unmanaged_jobs-${config_name}":
    command => "jenkins-jobs --conf ${inifile} delete --jobs-only $(ruby unmanaged_jobs.rb /etc/jenkins_jobs/${config_name})",
    timeout => $jenkins_jobs_update_timeout,
    path    => '/bin:/usr/bin:/usr/local/bin',
    require => File[$inifile],
    before  => Exec["jenkins_jobs_update-${config_name}"],
  }

# TODO: We should put in  notify Exec['jenkins_jobs_update']
#       at some point, but that still has some problems.
  file { $inifile:
    ensure  => file,
    mode    => '0400',
    content => template('jenkins_job_builder/jenkins_jobs.ini.erb'),
  }
}
