# @api private
class slave::mysql {
  include mysql::params

  package { $mysql::params::server_package_name:
    ensure => absent,
  }

  slave::db_config { 'mysql':
    ensure => absent,
  }
}
