# Cheap class to deploy an SSH provate key for use in contacting the freight server
# to upload deb packages for signing
#
class freight2::client {

  $pub_key  = ssh_keygen('freight_key','public')
  $priv_key = ssh_keygen('freight_key','private')

  file { '/var/lib/workspace/workspace/ssh_key_freight':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => 0400,
    content => "${priv_key}",
  }

  file { '/var/lib/workspace/workspace/ssh_key_freight.pub':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => 0644,
    content => "ssh-rsa ${pub_key} freight_key\n",
  }

}
