class rbot::service {
  service { 'rbot':
    ensure     => 'running',
    enable     => 'true',
    hasstatus  => 'true',
    hasrestart => 'false',
  }
}
