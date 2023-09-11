# @summary A Redmine server
class profiles::redmine (
) {
  include redmine

  $backup_path = $redmine::data_dir
  $backup_db_path = "${backup_path}/db"

  include profiles::backup::sender
  include postgresql::server

  postgresql::server::role { 'restic':
  }

  postgresql::server::database_grant { "restic-${redmine::db_name}":
    privilege => 'CONNECT',
    db        => $redmine::db_name,
    role      => 'restic',
  }

  postgresql::server::grant { "restic-${redmine::db_name}-tables":
    privilege   => 'SELECT',
    object_type => 'ALL TABLES IN SCHEMA',
    object_name => 'public',
    db          => $redmine::db_name,
    role        => 'restic',
  }

  postgresql::server::grant { "restic-${redmine::db_name}-sequences":
    privilege   => 'SELECT',
    object_type => 'ALL SEQUENCES IN SCHEMA',
    object_name => 'public',
    db          => $redmine::db_name,
    role        => 'restic',
  }

  file { $backup_db_path:
    ensure => directory,
    owner  => 'restic',
    mode   => '0600',
  }

  restic::repository { 'redmine':
    backup_cap_dac_read_search => true,
    backup_path                => $backup_path,
    backup_flags               => ['--exclude', "${backup_path}/git"],
    backup_pre_cmd             => ["pg_dump --file=${backup_db_path}/redmine.sql ${redmine::db_name}"],
  }
}
