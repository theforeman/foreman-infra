class java {
  package { "java":
    ensure => present,
    name => $osfamily ? {
      RedHat => $operatingsystemrelease ? {
        17 => "java-1.7.0-openjdk",
        default => "java-1.6.0-openjdk"
      },
      default => "openjdk-6-jdk"
    }
  }
}
