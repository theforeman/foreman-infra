define quassel::user(
  $key
) {

  # This is a horrid hack, but there's no easy non-interactive way to add or check for users
  exec { "add-${name}-to-quassel":
    command => "/bin/echo -e \"${name}\nfoo\nfoo\" | /usr/bin/quasselcore --add-user --configdir=/var/lib/quassel && /bin/touch /var/cache/quassel/${user}/user-created",
    creates => "/var/cache/quassel/${name}/user-created",
  }

  user { $name:
    ensure => present,
    shell  => '/usr/local/bin/quasselshell',
    home   => "/var/cache/quassel/${name}",
    groups => ['quassel'],
  }

  file { ["/var/cache/quassel/${name}","/var/cache/quassel/${name}/.ssh"]:
    ensure => directory,
    owner  => $name,
    mode   => 0700,
  }

  file { "/var/cache/quassel/${name}/.ssh/authorized_keys":
    ensure  => present,
    owner   => $name,
    mode    => 0600,
    content => "ssh-rsa ${key} ${name}",
  }

}
