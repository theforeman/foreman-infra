class unattended {
  if $::osfamily == 'Debian' {
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
}
