class gems {
  package {
    "rake":
      ensure => present,
      provider => 'gem';
    "bundler":
      ensure => present,
      provider => 'gem';
  }
}
