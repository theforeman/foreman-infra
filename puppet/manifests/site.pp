node default {
  include profiles::base
}

node /^backup\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::backup::receiver
}

node /^controller\d+\.jenkins\.[a-z]+\.theforeman\.org$/ {
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

node /^redmine\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::redmine
}

node /^repo-deb\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::repo::deb
}

node /^repo-rpm\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::repo::rpm
}

node /^website\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::website
}
