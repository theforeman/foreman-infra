node default {
  include profiles::base
}

node /^backup\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::backup::receiver
}

node /^controller\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::jenkins::controller
}

node /^discourse\d+\.([a-z]+\.)?theforeman\.org$/ {
  include profiles::base
  include profiles::discourse
}

node /^foreman\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::foreman
}

node /^(deb-)?node\d+\.jenkins\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::jenkins::node
}

node /^puppet\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::puppetserver
}

node /^redmine\d+\.([a-z]+\.)?theforeman\.org$/ {
  include profiles::base
  include profiles::redmine
}

node /^virt\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
}

node /^web\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::web
}
