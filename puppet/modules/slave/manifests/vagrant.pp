# A class to install vagrant on a jenkins slave
class slave::vagrant(
  Sensitive $username,
  Sensitive $password,
  Sensitive $tenant_name,
  String $user = 'jenkins',
  String $vagrant_version = '2.0.2',
  String $region = 'IAD',
) {
  $home = "/home/${user}"
  $ssh_key = "${home}/.ssh/id_rsa_rackspace"

  case $::osfamily {
    'RedHat': {
      $vagrant_source = "https://releases.hashicorp.com/vagrant/${vagrant_version}/vagrant_${vagrant_version}_x86_64.rpm"
      $vagrant_provider = 'rpm'
    }
    'Debian': {
      $vagrant_source = "https://releases.hashicorp.com/vagrant/${vagrant_version}/vagrant_${vagrant_version}_x86_64.deb"
      $vagrant_provider = 'dpkg'
    }
    default: { fail("Unknown osfamily ${::osfamily}") }
  }

  file { "/root/vagrant-package-${vagrant_version}":
    source => $vagrant_source,
  } ->
  file { '/usr/local/src/vagrant-openstack-provider-0.12.0.pre.ed73861.gem':
    source => 'https://downloads.theforeman.org/infra/vagrant-openstack-provider-0.12.0.pre.ed73861.gem',
  } ->
  package { 'vagrant':
    ensure   => latest,
    source   => "/root/vagrant-package-${vagrant_version}",
    provider => $vagrant_provider,
  } ->
  # old installs need to be migrated and that's an interactive UI. Easier to wipe out the old config
  exec { 'clean old vagrant':
    command => "rm -rf ${home}/.vagrant.d",
    onlyif  => "test -e ${home}/.vagrant.d/boxes/dummy/rackspace",
    path    => ['/bin', '/usr/bin'],
    user    => $user,
  } ->
  exec { 'vagrant plugin install /usr/local/src/vagrant-openstack-provider-0.12.0.pre.ed73861.gem':
    unless      => 'vagrant plugin list | grep vagrant-openstack-provider',
    environment => ["HOME=${home}", 'NOKOGIRI_USE_SYSTEM_LIBRARIES=yes'],
    user        => $user,
    cwd         => $home,
    provider    => 'shell',
    require     => Package['libxml2-dev'],
  } ->
  file { "${home}/.vagrant.d/Vagrantfile":
    ensure  => file,
    owner   => $user,
    group   => $user,
    mode    => '0600',
    content => template('slave/Vagrantfile.erb'),
  }

  file { '/root/vagrant-openstack-provider-0.12.0.pre.ed73861.gem':
    ensure => absent,
  }
}
