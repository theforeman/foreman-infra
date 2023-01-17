# @summary A shared secret storage
#
# The shared secret storage creates a group where all users have access
# to a shared directory for use with gopass. It is then expected that
# there are several git repositories within that directory. Each
# repository is created using:
# `git init --bare --shared=group therepo.git`
#
# @param group The group every user should be part of
# @param path The location to store the git repositories
# @param users The users who should be part of the group
#
# @see https://www.gopass.pw/
class secretsgit (
  String $group = 'secretsgit',
  Stdlib::Absolutepath $path = '/srv/secretsgit',
  Array[String] $users = [],
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
