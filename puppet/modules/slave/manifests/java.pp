class slave::java {
  package { 'java':
    ensure => present,
    name   => $::osfamily ? {
      'RedHat' => 'java-1.8.0-openjdk',
      default  => 'openjdk-8-jdk',
    },
  }
}
