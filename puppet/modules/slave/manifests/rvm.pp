# Various RVM config
class slave::rvm {
  gnupg_key { 'rvm_pkuczynski':
    ensure     => present,
    key_id     => '39499BDB',
    user       => 'root',
    key_source => 'https://rvm.io/pkuczynski.asc',
    key_type   => public,
  } ->
  class { '::rvm':
    version => '1.29.9',
  }

  if $::rvm_installed == true {
    rvm::system_user { 'jenkins':
      create  => false,
      require => User['jenkins'],
    }

    if $::architecture == 'x86_64' or $::architecture == 'amd64' {
      slave::rvm_config { 'ruby-2.0.0':
        version => 'ruby-2.0.0-p648',
      }
    }
    slave::rvm_config { 'ruby-2.1':
      version => 'ruby-2.1.5',
    }
    slave::rvm_config { 'ruby-2.2':
      version => 'ruby-2.2.5',
    }
    slave::rvm_config { 'ruby-2.3':
      version => 'ruby-2.3.5',
    }
    slave::rvm_config { 'ruby-2.4':
      version => 'ruby-2.4.3',
    }
    slave::rvm_config { 'ruby-2.5':
      version => 'ruby-2.5.1',
    }
    slave::rvm_config { 'ruby-2.6':
      version          => 'ruby-2.6.3',
      rubygems_version => '3.0.3',
    }
    slave::rvm_config { 'ruby-2.7':
      version          => 'ruby-2.7.0',
      rubygems_version => '3.1.2',
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
