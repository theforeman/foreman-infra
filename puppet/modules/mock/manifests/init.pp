class mock {
  package { "mock":
    ensure => present
  }

  user { "mock":
    ensure => present,
    managehome => true,
    require => Package["mock"]
  }

  mock::config { "el5-i386":
    version => "5",
    architecture => "i386"
  }

  mock::config { "el5-x86_64":
    version => "5",
    architecture => "x86_64"
  }

  mock::config { "el6-i386":
    version => "6",
    architecture => "i386"
  }

  mock::config { "el6-x86_64":
    version => "6",
    architecture => "x86_64"
  }
}
