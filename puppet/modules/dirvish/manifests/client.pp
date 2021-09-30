# Trivial class to include the dirvish keys on the clients
#
# Requires that /root/.ssh/authorized_keys is present
#
class dirvish::client (
  $pre_script    = 'undef',
  $pre_template  = 'undef',
  $declare_rsync = true
) {

  # Read the dirvish key from the puppetmaster
  $pub_key  = ssh_keygen({name => 'dirvish_key', public => 'true'})

  file_line { 'dirvish_ssh_pubkey':
    ensure => present,
    path   => '/root/.ssh/authorized_keys',
    line   => "ssh-rsa ${pub_key} dirvish_key",
  }

  $template_content = $pre_template ? {
    'undef' => template('dirvish/pre_client.sh.erb'),
    default => template($pre_template),
  }

  $content = $pre_script ? {
    'undef' => $template_content,
    default => $pre_script,
  }

  # Basic pre-run script
  file { '/etc/dirvish':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/etc/dirvish/pre_client':
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => $content,
  }

  # Dirvish depends on rsync
  if $declare_rsync {
    ensure_packages(['rsync'])
  }

}
