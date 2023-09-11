class unattended {
  if $facts['os']['family'] == 'Debian' {
    class { 'unattended_upgrades':
      auto      => { 'reboot' => false },
      blacklist => [
        'docker-ce',
        'openjdk-8-jdk',
        'openjdk-8-jdk-headless',
        'openjdk-8-jre',
        'openjdk-8-jre-headless',
        'openjdk-11-jdk',
        'openjdk-11-jdk-headless',
        'openjdk-11-jre',
        'openjdk-11-jre-headless',
      ],
      mail      => { 'to' => 'sysadmins', },
    }
  }

  if $facts['os']['family'] == 'RedHat' {
    class { 'yum_cron':
      apply_updates    => true,
      mailto           => 'sysadmins',
      exclude_packages => ['kernel*', 'java*', 'jenkins'],
    }
  }
}
