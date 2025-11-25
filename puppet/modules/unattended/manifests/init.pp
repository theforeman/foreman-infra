class unattended {
  if $facts['os']['family'] == 'Debian' {
    class { 'unattended_upgrades':
      auto          => { 'reboot' => false },
      blacklist     => [
        'openjdk-17-jdk',
        'openjdk-17-jdk-headless',
        'openjdk-17-jre',
        'openjdk-17-jre-headless',
      ],
      extra_origins => [
        'site=apt.grafana.com,component=main',
      ],
      mail          => { 'to' => 'sysadmins', },
    }
  }

  if $facts['os']['family'] == 'RedHat' {
    if $trusted['certname'] =~ /^node\d+\.jenkins\.[a-z]+\.theforeman\.org$/ {
      $reboot = 'when-needed'
      $reboot_command = '/usr/local/sbin/reboot-jenkins-node'
    } elsif $trusted['certname'] =~ /^(repo-deb|repo-rpm|backup|website)\d+\.[a-z]+\.theforeman\.org$/ {
      $reboot = 'when-needed'
      $reboot_command = '/usr/local/sbin/reboot-inactive-system'
    } else {
      $reboot = 'never'
      $reboot_command = "shutdown -r +5 'Rebooting after applying package updates'"
    }

    class { 'yum_cron':
      apply_updates    => true,
      mailto           => 'sysadmins',
      exclude_packages => ['java*', 'jenkins'],
      reboot           => $reboot,
      reboot_command   => $reboot_command,
    }
  }
}
