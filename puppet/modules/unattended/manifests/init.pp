class unattended {
  if $facts['os']['family'] == 'Debian' {
    class { 'unattended_upgrades':
      auto      => { 'reboot' => false },
      blacklist => [
        'openjdk-17-jdk',
        'openjdk-17-jdk-headless',
        'openjdk-17-jre',
        'openjdk-17-jre-headless',
      ],
      mail      => { 'to' => 'sysadmins', },
    }
  }

  if $facts['os']['family'] == 'RedHat' {
    class { 'yum_cron':
      apply_updates    => true,
      mailto           => 'sysadmins',
      exclude_packages => ['kernel*', 'kmod-*', 'java*', 'jenkins'],
    }
  }
}
