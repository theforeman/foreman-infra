class ntp($ensure='running', $enable=true) {
  case $::operatingsystem {
    debian, ubuntu: {
      $supported  = true
      $pkg_name   = [ 'ntp' ]
      $svc_name   = 'ntp'
      $config     = '/etc/ntp.conf'
      $config_tpl = 'ntp.conf.debian.erb'
      $servers    = [ '0.debian.pool.ntp.org iburst',
                      '1.debian.pool.ntp.org iburst',
                      '2.debian.pool.ntp.org iburst',
                      '3.debian.pool.ntp.org iburst' ]
    }
    centos, redhat, fedora: {
      $supported  = true
      $pkg_name   = [ 'ntp' ]
      $svc_name   = 'ntpd'
      $config     = '/etc/ntp.conf'
      $config_tpl = 'ntp.conf.el.erb'
      $servers    = [ '0.centos.pool.ntp.org',
                      '1.centos.pool.ntp.org',
                      '2.centos.pool.ntp.org' ]
    }
  }

  package { 'ntp':
    ensure => $package_ensure,
    name   => $pkg_name,
  }

  file { $config:
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => '0644',
    content => template("${module_name}/${config_tpl}"),
    require => Package[$pkg_name],
  }

  service { 'ntp':
    ensure     => $ensure,
    enable     => $enable,
    name       => $svc_name,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => [ Package[$pkg_name], File[$config] ],
  }
}
