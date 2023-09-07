node default {
  include profiles::base
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
  include profiles::backup::receiver
}

node /^redmine\d+\.([a-z]+\.)?theforeman\.org$/ {
  include profiles::base
  include profiles::redmine
}

node /^web\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::web
}
