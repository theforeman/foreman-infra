class gems {
  package {
    "rubygems":
      ensure => present;
    "rake":
      ensure => present,
      provider => 'gem';
    "bundler":
      ensure => present,
      provider => 'gem';
    "brakeman":
      ensure => present,
      provider => 'gem';
    "fpm":
      ensure => present,
      provider => 'gem';
    "hub":
      ensure => present,
      provider => 'gem';
    "rspec-puppet":
      ensure   => present,
      provider => 'gem';
  }
}
