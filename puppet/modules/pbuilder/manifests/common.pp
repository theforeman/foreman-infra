# pbuilder puppet module
# See README for more infos
#
# Copyright © 2007 Raphaël Pinson <raphink@gmail.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


# Class: pbuilder::common
#
# This class is imported from the pbuilder type. It manages generic resources for pbuilder.
#
# Parameters:
#
# Actions:
#   Installs the pbuilder package and UNIX group.
#
# Requires:
#
# Sample Usage:
#   include "pbuilder::common"
#
class pbuilder::common {

   # Call this class from within the pbuilder definition


   package { "pbuilder":
      ensure => installed
   }

   group { "pbuilder":
      ensure => present
   }

}

