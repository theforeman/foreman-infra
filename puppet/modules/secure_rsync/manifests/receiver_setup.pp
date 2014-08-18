# Define which deploys the key for a specific user
#
# === Parameters:
#
# $name:           name of the key (required)
#
# $user:           user to own the key (required)
#
# $homedir:        home directory the user
#
# $allowed_ips:    list of allowed ips in the authorized keys file
#                  not used if $foreman_search is provided
#
# $foreman_search: string to search in the foreman API, unused by default
#                  if specified, uses the foreman search puppet function to
#                  get IP addresses matching the required string.
#
# $script_content: content of a script that'll be run by sshd when the user
#                  connects with the key
#
define secure_rsync::receiver_setup (
  $user,
  $homedir        = "/home/${user}",
  $foreman_search = false,
  $allowed_ips    = [],
  $script_content,
  $ssh_key_name   = "${name}_key",
) {

  # Disable password, we want this to be keys only
  user { $user:
    ensure     => present,
    home       => $homedir,
    managehome => true,
    password   => '!',
  }
  ->
  file { "${homedir}/.ssh":
    ensure => directory,
    owner  => $user,
    mode   => '0700',
  }

  # Read the web key from the puppetmaster
  $pub_key  = ssh_keygen({name => $ssh_key_name, public => 'public'})

  if $foreman_search {
    # Get the IPs of the Web Builder slaves from foreman
    $ip_data=foreman({
      'item'         => 'fact_values',
      'search'       => $foreman_search,
      'foreman_user' => $::foreman_api_user,
      'foreman_pass' => $::foreman_api_password,
      })
  }

  file { "${homedir}/.ssh/authorized_keys":
    ensure  => present,
    owner   => $user,
    mode    => '0700',
    content => template('secure_rsync/auth_keys.erb'),
  }

  # Create validation script for secure connections only
  file { "${homedir}/bin":
    ensure => directory,
    owner  => $user,
    mode   => '0700',
  }

  file { "${homedir}/bin/secure_${name}":
    ensure  => present,
    owner   => $user,
    mode    => '0700',
    content => $script_content,
  }
}
