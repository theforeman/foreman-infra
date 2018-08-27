class unattended {
  if $::osfamily == 'Debian' {
    class { 'unattended_upgrades':
      auto      => { 'reboot' => false },
      blacklist => [
        'docker-ce',
        'openjdk-8-jre',
        'openjdk-8-jre-headless',
        'oracle-java8-installer',
        'oracle-java8-set-default',
      ],
      mail => { 'to' => 'sysadmins', },
    }
  }
}
