class java {
  package { "java":
    ensure => present,
    name => $osfamily ? {
      RedHat => "java-1.6.0-openjdk",
      default => "openjdk-6-jdk"
    }
  }
}
