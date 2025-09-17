class openvox_repo::yum() {
  $os_name = $facts['os']['name'] ? {
    'Fedora' => 'fedora',
    'Amazon' => 'amazon',
    default  => 'el',
  }

  yumrepo { 'openvox':
    descr    => "OpenVox ${openvox_repo::release} ${os_name} ${facts['os']['release']['major']} Repository",
    baseurl  => "https://yum.voxpupuli.org/openvox${openvox_repo::release}/${os_name}/${facts['os']['release']['major']}/\$basearch",
    gpgcheck => '1',
    gpgkey   => 'https://yum.voxpupuli.org/GPG-KEY-openvox.pub',
    enabled  => '1',
  }
}
