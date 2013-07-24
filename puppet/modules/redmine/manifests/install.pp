class redmine::install {
  case $redmine::db_adapter {
    'sqlite': {  include 'sqlite3' }
    default: {fail("db_adapter ${redmine::db_adapter} is not supported - patches welcomed")}
  }

  # requires redhat-lsb-core for apache to work
  include 'git', 'apache'

  package{'passenger':
    ensure  => installed,
    name    => 'mod_passenger',
    require => [Yumrepo['foreman'],Package['apache']], # we are not using our own apache module,
    notify  => Service['apache'],                      # so I'm forced for inter module dependencies
  }

  yumrepo{'foreman':
    baseurl  => 'http://yum.theforeman.org/releases/latest/el6/$basearch',
    enabled  => 1,
    gpgcheck => 0,
  }

  # we don't package rubygem-bundler for centos anymore, so rubygems
  # is installed and we get bundler from gem sources
  package{['rubygems','ruby-devel', 'gcc']:
    ensure  => present,
  }
  ->
  package{'bundler':
    ensure   => present,
    provider => 'gem',
  }

  git::repo {'redmine':
    target => $redmine::local_dir,
    source => $redmine::upstream_repo,
  }
}
