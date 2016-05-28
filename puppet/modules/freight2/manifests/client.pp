# Cheap class to deploy an SSH provate key for use in contacting the freight server
# to upload deb packages for signing
#
class freight::client {

  $pub_key  = ssh_keygen('freight_key','public')
  $priv_key = ssh_keygen('freight_key','private')

  file { '/root/.ssh/id_freight':
    owner   => 'root',
    group   => 'root',
    mode    => 0400,
    content => "${priv_key}",
  }

  file { '/root/.ssh/id_freight.pub':
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    content => "ssh-rsa ${pub_key} freight_key\n",
  }

}
