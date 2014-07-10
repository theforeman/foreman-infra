class slave::swap($file = '/swap', $size_mb = 2048) {
  exec { 'create-swap':
    command => "/bin/dd if=/dev/zero of=${file} bs=1M count=${size_mb}",
    creates => $file,
  } ->
  exec { 'enable-swap':
    command => "/sbin/mkswap ${file} && /sbin/swapon ${file}",
    unless  => "/sbin/swapon -s | grep ${file}",
  } ->
  mounttab { 'swap':
    ensure   => present,
    device   => $file,
    fstype   => swap,
    options  => 'defaults',
    provider => augeas,
  }
}
