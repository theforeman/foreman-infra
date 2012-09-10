class java {
  package { "java":
    ensure => present,
    name => $osfamily ? {
      Debian => "openjdk-6-jdk",
      RedHat => "java-1.6.0-openjdk"
    }
  }
}
