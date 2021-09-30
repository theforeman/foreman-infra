# @summary Define a vault to store backups
define dirvish::vault(
  $client,
  $tree,
  $preclient      = false,
  $excludes       = [],
  $expire_default = '+30 days',
  $expire_rules   = ['mday { 1 } +6 months'],
) {
  file { "${dirvish::backup_location}/${name}":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { "${dirvish::backup_location}/${name}/dirvish":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { "${dirvish::backup_location}/${name}/dirvish/default.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dirvish/vault.erb'),
  }
  ->
  # Initialize the vault. This could take a while, so we disable the timeout.
  # Sadly 'creates' and 'refreshonly' work as an OR pair, so instead we
  # look for the history file - this will only exist if there has been at least
  # one successful backup
  exec { "Initialize Dirvish Vault: ${name}":
    timeout => 0,
    command => "/usr/bin/dirvish --init --vault ${name} --image initial",
    creates => "${dirvish::backup_location}/${name}/dirvish/default.hist",
    require => File['/etc/dirvish/master.conf'],
  }
}
