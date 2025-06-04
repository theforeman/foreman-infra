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
    class { 'yum_cron':
      apply_updates    => true,
      mailto           => 'sysadmins',
      exclude_packages => ['java*', 'jenkins'],
    }
  }
}
