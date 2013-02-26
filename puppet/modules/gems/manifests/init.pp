class gems {
  package {
    "rubygems":
      ensure => present;
    "rake":
      ensure  => present,
      require => Package['rubygems'],
      provider => 'gem';
    "bundler":
      ensure  => present,
      require => Package['rubygems'],
      provider => 'gem';
    "brakeman":
      ensure  => present,
      require => Package['rubygems'],
      provider => 'gem';
    "fpm":
      ensure  => present,
      require => Package['rubygems'],
      provider => 'gem';
    "hub":
      ensure  => present,
      require => Package['rubygems'],
      provider => 'gem';
    "rspec-puppet":
      ensure   => present,
      provider => 'gem';
  }
}
