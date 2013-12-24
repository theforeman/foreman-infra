class slave::vagrant($username, $api_key) {
  $home = '/home/jenkins'
  $ssh_key = "${home}/.ssh/id_rsa_rackspace"

  class { '::vagrant':
    git_hash => 'a40522f5fabccb9ddabad03d836e120ff5d14093',
    version  => '1.3.5',
  } ->
  exec { 'vagrant plugin install vagrant-rackspace':
    unless      => 'vagrant plugin list | grep vagrant-rackspace',
    environment => ["HOME=${home}", 'NOKOGIRI_USE_SYSTEM_LIBRARIES=yes'],
    user        => 'jenkins',
    cwd         => $home,
    provider    => 'shell',
    require     => Package['libxml2-dev'],
  } ->
  exec { 'vagrant box add dummy':
    command     => 'vagrant box add dummy https://github.com/mitchellh/vagrant-rackspace/raw/master/dummy.box',
    unless      => 'vagrant box list | grep dummy',
    environment => ["HOME=${home}"],
    user        => 'jenkins',
    cwd         => $home,
    provider    => 'shell',
  } ->
  file { "${home}/.vagrant.d/Vagrantfile":
    ensure  => file,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => 0600,
    content => template('slave/Vagrantfile.erb'),
  }

  exec { "/usr/bin/ssh-keygen -t rsa -f ${ssh_key}":
    creates => $ssh_key,
  }
}
