class deploy::slave {
  # Adapted from secure_rsync for a pure ssh solution
  $user = 'jenkins'
  $dir  = '/var/lib/workspace/workspace/deploy_key'

  $pub_key  = ssh_keygen({name => 'deploy_key', public => 'public'})
  $priv_key = ssh_keygen({name => 'deploy_key'})

  file { $dir:
    ensure => directory,
    owner  => $user,
    mode   => '0700',
  }

  file { "${dir}/deploy_key":
    owner   => $user,
    mode    => '0400',
    content => $priv_key,
  }

  file { "${dir}/deploy_key.pub":
    owner   => $user,
    mode    => '0644',
    content => "ssh-rsa ${pub_key} deploy_key from puppetmaster\n",
  }
}
