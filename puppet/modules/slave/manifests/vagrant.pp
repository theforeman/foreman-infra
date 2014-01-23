class slave::vagrant($username, $api_key) {
  $home = '/home/jenkins'
  $ssh_key = "${home}/.ssh/id_rsa_rackspace"

  case $::osfamily {
    'RedHat': {
      $vagrant_source = 'https://dl.bintray.com/mitchellh/vagrant/vagrant_1.4.2_x86_64.rpm'
      $vagrant_provider = 'rpm'
    }
    'Debian': {
      $vagrant_source = 'https://dl.bintray.com/mitchellh/vagrant/vagrant_1.4.2_x86_64.deb'
      $vagrant_provider = 'dpkg'
    }
    default: { fail("Unknown osfamily ${::osfamily}") }
  }

  package { 'vagrant':
    ensure   => installed,
    source   => $vagrant_source,
    provider => $vagrant_provider,
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
    user    => 'jenkins',
  } ->
  file { $ssh_key:
    owner => 'jenkins',
    group => 'jenkins',
  } ->
  file { "${ssh_key}.pub":
    owner => 'jenkins',
    group => 'jenkins',
  }
}
