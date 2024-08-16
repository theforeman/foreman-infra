node /^jenkins-controller.*/ {
  include profiles::jenkins::controller
}

node /^jenkins-(deb-)?node.*/ {
  sudo::conf { 'vagrant':
    content => 'vagrant ALL=(ALL) NOPASSWD: ALL',
  }

  include profiles::jenkins::node
}

node /^web.*/ {
  include profiles::web
}

node /^backup.*/ {
  include profiles::backup::receiver
}

node /^redmine.*/ {
  include profiles::redmine
}

node /^discourse.*/ {
  include profiles::discourse
}

node /^repo-deb.*/ {
  include profiles::repo::deb
}

node /^repo-rpm.*/ {
  include profiles::repo::rpm
}
