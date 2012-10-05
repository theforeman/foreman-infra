class pbuilder::cowbuilder::common inherits pbuilder::common {
  package {'cowbuilder':
    ensure => installed,
  }

  file {'/etc/pbuilderrc':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    content => '# file managed by puppet
MIRRORSITE="http://ftp.debian.org/debian"

DEBBUILDOPTS="-sa"
unset DEBOOTSTRAPOPTS

NAME=$(sed -e "s@.*/base-\([^ \t/]\+\)\.cow.*@\1@" <<<$SUDO_COMMAND)

if [ -z $NAME ]; then
  echo "W: Could not parse pbuilder name"
else
  if [ -d "/etc/pbuilder/${NAME}/apt" ]; then
    APTCONFDIR="/etc/pbuilder/${NAME}/apt"
  fi
  
  if [ -f "/etc/pbuilder/${NAME}/pbuilderrc" ]; then
    echo "I: Including /etc/pbuilder/${NAME}/pbuilderrc" >&2
    . "/etc/pbuilder/${NAME}/pbuilderrc"
  else
    echo "I: Could not find /etc/pbuilder/${NAME}/pbuilderrc" >&2
  fi
fi
',
  }
}
