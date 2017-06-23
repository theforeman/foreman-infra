class java {
  package { "java":
    ensure => present,
    name => $osfamily ? {
      'RedHat' => "java-1.7.0-openjdk",
      default  => "default-jdk",
    }
  }
}
