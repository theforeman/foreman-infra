# rbenv Configuration
# @api private
class jenkins_node::rbenv {
  file { '/home/jenkins/.rbenv':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  class { 'rbenv':
    install_dir => '/home/jenkins/.rbenv',
    require     => [File['/home/jenkins/.rbenv'], Package['gcc-c++']],
    user        => 'jenkins',
  }

  ensure_packages(['gcc-c++'])

  rbenv::build { '3.1.0': }
  rbenv::build { '3.0.4': }
  rbenv::build { '2.7.6': }
}
