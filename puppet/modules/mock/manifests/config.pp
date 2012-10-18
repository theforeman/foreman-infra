define mock::config(
  $version,
  $architecture,
  $ensure = 'present'
) {

  validate_re($ensure, '^(present|absent)$',
  "${ensure} is not support for ensure. Allowed values are 'present' and 'absent'.")

  file { "/etc/mock/$title.cfg":
    ensure => $ensure,
    owner => 'mock',
    group => 'mock',
    mode => '0755',
    content => template("mock/mock.cfg.erb"),
    require => Package["mock"]
  }
}
