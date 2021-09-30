# @summary Install Dirvish
# @api private
class dirvish::install {

  package { 'dirvish':
    ensure => installed,
  }

  file { $dirvish::backup_location:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${dirvish::backup_location}/ssh":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  # This clever function creates SSH keys on the puppetmaster and allows them to
  # be read back and passed to the puppet clients

  # Read the dirvish SSH key (and create it if necessary)

  # Generate RSA keys reliably
  $pub_key  = ssh_keygen({name => 'dirvish_key', public => 'true'})
  $priv_key = ssh_keygen({name => 'dirvish_key'})

  file { "${dirvish::backup_location}/ssh/dirvish_key":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $priv_key,
  }

  file { "${dirvish::backup_location}/ssh/dirvish_key.pub":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "ssh-rsa ${pub_key} dirvish_key\n",
  }

}
