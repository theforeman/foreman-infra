# Define which deploys the key for a specific user
#
# @param user
#   User to own the key
#
# @param script_content
#   Content of a script that'll be run by sshd when the user connects with the
#   key
#
# @param homedir
#   Home directory the user
#
# @param allowed_ips
#   List of allowed ips in the authorized keys file. Unused if $foreman_search
#   is provided
#
# @param foreman_search
#   String to search in the foreman API, unused by default if specified, uses
#   the foreman search puppet function to get IP addresses matching the
#   required string.
#
define secure_ssh::receiver_setup (
  String $user,
  String $script_content,
  Stdlib::Absolutepath $homedir = "/home/${user}",
  Optional[String] $foreman_search = undef,
  Array[Stdlib::IP::Address] $allowed_ips = [],
  String $ssh_key_name = "${name}_key",
) {

  # Disable password, we want this to be keys only
  user { $user:
    ensure     => present,
    home       => $homedir,
    managehome => true,
    password   => '!',
  }

  # Created above, but this ensures futher chaining is correct
  file { $homedir:
    ensure => directory,
    owner  => $user,
  }

  file { "${homedir}/.ssh":
    ensure => directory,
    owner  => $user,
    mode   => '0700',
  }

  # Read the public key from the puppetmaster
  $pub_key  = ssh_keygen({name => $ssh_key_name, public => 'public'})

  if $foreman_search {
    # Get the IPs of the uploaders from foreman
    $ip_data=foreman({
        'item'         => 'fact_values',
        'search'       => $foreman_search,
        'foreman_user' => $::foreman_api_user,
        'foreman_pass' => $::foreman_api_password,
    })
  }

  file { "${homedir}/.ssh/authorized_keys":
    ensure  => file,
    owner   => $user,
    mode    => '0700',
    content => template('secure_ssh/auth_keys.erb'),
  }

  # Create validation script for secure connections only
  file { "${homedir}/bin":
    ensure => directory,
    owner  => $user,
    mode   => '0700',
  }

  file { "${homedir}/bin/secure_${name}":
    ensure  => file,
    owner   => $user,
    mode    => '0700',
    content => $script_content,
  }
}
