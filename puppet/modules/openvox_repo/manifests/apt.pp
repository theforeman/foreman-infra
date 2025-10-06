class openvox_repo::apt () {
  include apt

  $os_name = downcase($facts['os']['name'])
  $release = "${os_name}${facts['os']['release']['major']}"

  apt::source { 'openvox':
    comment  => "OpenVox ${openvox_repo::release} ${release} Repository",
    location => 'https://apt.voxpupuli.org',
    release  => $release,
    repos    => "openvox${openvox_repo::release}",
    key      => {
      'name'   => 'openvox-keyring.gpg',
      'source' => 'https://apt.voxpupuli.org/openvox-keyring.gpg',
    },
  }
}
