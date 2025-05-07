node default {
  include profiles::base
}

node /^backup\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::backup::receiver
  include profiles::monitoring::client
}

node /^controller\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::jenkins::controller
  include profiles::monitoring::client
}

node /^discourse\d+\.([a-z]+\.)?theforeman\.org$/ {
  include profiles::base
  include profiles::discourse
  include profiles::monitoring::client
}

node /^foreman\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::foreman
  include profiles::monitoring::client
}

node /^(deb-)?node\d+\.jenkins\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::jenkins::node
  include profiles::monitoring::client
}

node /^puppet\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::puppetserver
  include profiles::monitoring::client
}

node /^redmine\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::redmine
  include profiles::monitoring::client
}

node /^repo-deb\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::repo::deb
  include profiles::monitoring::client
}

node /^repo-rpm\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::repo::rpm
  include profiles::monitoring::client
}

node /^website\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::website
  include profiles::monitoring::client
}
