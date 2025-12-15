node /^jenkins-controller.*/ {
  include profiles::jenkins::controller
}

node /^jenkins-(deb-)?node.*/ {
  sudo::conf { 'vagrant':
    content => 'vagrant ALL=(ALL) NOPASSWD: ALL',
  }

  include profiles::jenkins::node
}

node /^website.*/ {
  include profiles::website
}

node /^backup.*/ {
  include profiles::backup::receiver
}

node /^redmine.*/ {
  include profiles::base
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
