# @summary Create the Dirvish configuration
# @api private
class dirvish::config {
  # The main config file
  file { '/etc/dirvish/master.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dirvish/master.conf.erb'),
  }

  if $dirvish::symlink_latest {
    file { '/etc/dirvish/post-server':
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('dirvish/post-server.erb'),
    }
  }

  create_resources(dirvish::vault, $dirvish::vaults)
}
