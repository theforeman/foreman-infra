# Various RVM config
# @api private
class slave::rvm {
  ensure_packages(['wget'])

  gnupg_key { 'rvm_pkuczynski':
    ensure     => present,
    key_id     => '105BD0E739499BDB',
    user       => 'root',
    key_source => 'https://rvm.io/pkuczynski.asc',
    key_type   => public,
    require    => Package['wget'],
  } ->
  class { 'rvm':
    version => '1.29.12',
  } ->
  Class['Rvm::System']

  if $facts['rvm_installed'] {
    rvm::system_user { 'jenkins':
      create  => false,
      require => User['jenkins'],
    }

    slave::rvm_config { 'ruby-2.4':
      ensure  => absent,
      version => 'ruby-2.4.3',
    }
    slave::rvm_config { 'ruby-2.5':
      ensure  => absent,
      version => 'ruby-2.5.1',
    }
    slave::rvm_config { 'ruby-2.7':
      version          => 'ruby-2.7.4',
      rubygems_version => '3.1.6',
    }
    slave::rvm_config { 'ruby-3.0':
      version          => 'ruby-3.0.4',
      rubygems_version => '3.2.3',
    }
    slave::rvm_config { 'ruby-3.1':
      version          => 'ruby-3.1.2',
      rubygems_version => '3.3.3',
    }

    # Cleanup log dirs
    file { '/etc/cron.daily/rvm_log_cleaner':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => "#!/bin/sh\n[ -e /usr/local/rvm/log ] || exit 0;\nfind /usr/local/rvm/log -maxdepth 1 -mtime +31 -exec rm -rf {} +\n",
    }
  }
}
