# @summary scripts to manage fastly CDN purging
#
class fastly_purge {
  file { '/usr/local/bin/fastly-purge':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file("${module_name}/fastly-purge.sh"),
  }

  file { '/usr/local/bin/fastly-purge-find':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file("${module_name}/fastly-purge-find.sh"),
  }
}
