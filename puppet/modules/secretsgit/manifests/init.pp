class secretsgit(
  String $group = 'secretsgit',
  Stdlib::Absolutepath $path = '/srv/secretsgit',
  Array[String] $users = []
) {

  group { $group:
    ensure => present,
  }

  file { $path:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '2770',
  }

  $users.each |String $user| {
    User<| title == $user |> { groups +> [$group] }
  }

}
