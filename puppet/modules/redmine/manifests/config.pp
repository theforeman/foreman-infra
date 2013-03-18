class redmine::config {

  Exec {
    environment => ["HOME=${redmine::local_dir}","RAILS_ENV=${redmine::environment}",'REDMINE_LANG=en'],
    user        => $redmine::user,
    cwd         => $redmine::local_dir,
    require     => Exec['redmine-bundle']
  }

  # Create session store
  exec { 'session_store':
    command => 'bundle exec rake generate_session_store',
    creates => "${redmine::local_dir}/config/initializers/secret_token.rb",
  }

  # Perform rails migrations
  exec { 'rails_migrations':
    command => 'bundle exec rake db:migrate',
    creates => "${redmine::local_dir}/db/schema.rb",
    before  => Service['apache'],
  }

  # the user that execute redmine
  user { $redmine::user:
    ensure     => 'present',
    shell      => '/bin/false',
    managehome => true,
    home       => $redmine::user_home,
  }

  file{ $redmine::user_home:
    ensure  => directory,
    owner   => $redmine::user,
    mode    => '0701',
    require => User[$redmine::user]
  }

  file{ "${redmine::local_dir}/config/database.yml":
    ensure  => 'present',
    owner   => $redmine::user,
    content => template('redmine/database.yml.erb'),
    mode    => '0640',
    require => Git::Repo['redmine'],
  }

  file {[$redmine::local_dir, "${redmine::local_dir}/db", "${redmine::local_dir}/config/initializers", "${redmine::local_dir}/config/environments"]:
    ensure  => directory,
    owner   => $redmine::user,
    mode    => '0644',
    before  => Service['apache'],
  }

  file {["${redmine::local_dir}/log", "${redmine::local_dir}/tmp", "${redmine::local_dir}/files"]:
    ensure  => directory,
    owner   => $redmine::user,
    recurse => true,
    mode    => '0644',
    before  => Service['apache'],
  }

  file {["${redmine::local_dir}/config/environment.rb", "${redmine::local_dir}/config.ru"]:
    owner   => $redmine::user,
    mode    => '0644',
    recurse => true,
    require => User[$redmine::user],
    before  => Service['apache'],
  }

  exec{'redmine-bundle':
    command => 'bundle install --path vendor/bundle --without development test rmagick',
    creates => "${redmine::local_dir}/vendor/bundle",
    require => [ User[$redmine::user],
                 File["${redmine::local_dir}/config/configuration.yml"],
                 File["${redmine::local_dir}/config/database.yml"],
               ],
  }

  file {"${redmine::local_dir}/config/configuration.yml":
    ensure  => present,
    content => template('redmine/configuration.yml.erb'),
    before  => Service['apache'],
  }

  apache::vhost {'redmine':
    config_content => template('redmine/vhost.erb'),
    docroot        => "${redmine::local_dir}/public",
    aliases        => $redmine::site_aliases,
  }

  # Log rotation
  file { '/etc/logrotate.d/redmine.conf':
    ensure  => present,
    content => template('redmine/logrotate.conf.erb'),
    owner   => 'root',
    group   => 'root'
  }

  #plugin{'votes':
  #  git_url => 'https://github.com/panicinc/redmine_vote.git'
  #}

}
