node default {
  include profiles::base
}

node /^controller\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::jenkins::controller
}

node /^discourse\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  # TODO profiles::discourse
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
  include dirvish::client
  include exim # TODO
  include redmine
}

node /^web\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::web
}
