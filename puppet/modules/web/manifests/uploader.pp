# Cheap class to deploy an SSH private key for use in contacting the web server
# to upload the compiled static site
#
class web::uploader {

  $pub_key  = ssh_keygen({name => 'web_key', public => 'public'})
  $priv_key = ssh_keygen({name => 'web_key'})

  file { '/var/lib/workspace/workspace':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => 0664,
  }

  file { '/var/lib/workspace/workspace/ssh_key_web':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => 0400,
    content => "${priv_key}",
  }

  file { '/var/lib/workspace/workspace/ssh_key_web.pub':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => 0644,
    content => "ssh-rsa ${pub_key} puppet_web_key\n",
  }
}
