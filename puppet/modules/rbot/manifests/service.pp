class rbot::service {
  service { 'rbot':
    ensure     => 'running',
    hasstatus  => 'true',
    hasrestart => 'false',
  }
}
