# @summary Include Dirvish keys on a client
#
# @param pre_script
#   An optional pre_client script. If not specified, the template is rendered
# @param pre_template
#   The ERB template to render for the pre_client hook
# @param declare_rsync
#   Whether to ensure rsync is installed or not
class dirvish::client (
  Optional[String] $pre_script = undef,
  String[1] $pre_template  = 'dirvish/pre_client.sh.erb',
  Boolean $declare_rsync = true,
) {
  # Read the dirvish key from the puppetmaster
  $pub_key = ssh_keygen({name => 'dirvish_key', public => 'true'})

  ssh_authorized_key { 'dirvish_key':
    ensure => present,
    user   => 'root',
    type   => 'ssh-rsa',
    key    => $pub_key,
  }

  $content = pick($pre_script, template($pre_template))

  # Basic pre-run script
  file { '/etc/dirvish':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/etc/dirvish/pre_client':
    ensure  => file,
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
