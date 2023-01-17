node default {
  include profiles::base
}

node /^controller\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::jenkins::controller
  include dirvish::client
}

node /^discourse\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  # TODO profiles::discourse
  include dirvish::client
}

node /^foreman\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::foreman
  # TODO: include dirvish::client
}

node /^(deb-)?node\d+\.jenkins\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::jenkins::node
}

node /^puppet\d+\.[a-z]+\.theforeman\.org$/ {
  include profiles::base
  include profiles::puppetserver
  include dirvish
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
