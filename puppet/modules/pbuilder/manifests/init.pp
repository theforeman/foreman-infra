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

# Define: pbuilder
#
# This definition provides a pbuilder resource.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
define pbuilder ($ensure="present", 
                 $release=$lsbdistcodename, $arch=$architecture, $methodurl="", 
                 $debbuildopts="-b", $bindmounts="",
                 $bindir="/usr/local/bin", $chrootdir="/var/chroot/pbuilder",
                 $confdir="/etc/pbuilder", $cachedir="/var/cache/pbuilder") {

   
   # Include commons (package and group)
   include "pbuilder::common"

   $script     = "${bindir}/pbuilder-${name}"

   # directories
   $pbuilder_confdir     = "${confdir}/${name}"
   $pbuilder_cachedir    = "${cachedir}/${name}"
   $builddir             = "${pbuilder_cachedir}/build"
   $resultdir            = "${pbuilder_cachedir}/result"
   $aptcachedir          = "${pbuilder_cachedir}/aptcache"
   
   # conf
   $pbuilderrc  = "${pbuilder_confdir}/pbuilderrc"
   $aptconfdir  = "${pbuilder_confdir}/apt.config"
   $hookdir     = "${pbuilder_confdir}/hooks"

   # base
   $basetgz     = "${chrootdir}/base_${name}.tgz"


   case $ensure {
      present: {
         # LEGACY: ensure all the dirs exist recursively
         #         the file type can't do that yet
         exec {
            "confdir-${name}":
               command => "/bin/mkdir -p ${pbuilder_confdir}",
               creates => "${pbuilder_confdir}";
            "bindir-${name}":
               command => "/bin/mkdir -p ${bindir}",
               creates => "$bindir";
            "chrootdir-${name}":
               command => "/bin/mkdir -p ${chrootdir}",
               creates => "$chrootdir";
            "cachedir-${name}":
               command => "/bin/mkdir -p ${pbuilder_cachedir}",
               creates => "$pbuilder_cachedir";
         }

         file { 
             $script:
                ensure  => present,
                mode    => 755,
                content => template("pbuilder/script.erb"),
                require => Exec["bindir-${name}"];
#            $link:
#               ensure  => link,
#               target  => $script,
#               require => Exec["bindir-${name}"];
           [ $builddir, $resultdir, $aptcachedir ]:
               ensure  => directory,
               require => Exec["cachedir-${name}"];
           $aptconfdir:
               ensure  => directory,
               recurse => true,
               require => Exec["confdir-${name}"];
           $hookdir:
               ensure  => directory,
               recurse => true,
# TODO hookdir source
#              source  => "puppet://${server}/pbuilder/hookdir/${site}",
               require => Exec["confdir-${name}"];
           $pbuilderrc:
               ensure  => present,
               content => template("pbuilder/pbuilderrc.erb"),
               require => Exec["confdir-${name}"];

         }

#         apt::sources_list { 
#            "pbuilder-${name}-$operatingsystem":
#               ensure  => present,
#               content => template("apt/${operatingsystem}/${operatingsystem}.list.erb"),
#               confdir => "${aptconfdir}",
#               require => [ File["$aptconfdir/sources.list.d"], Exec["confdir-${name}"] ];
#            "pbuilder-${name}-Hebex":
#               ensure  => present,
#               content => template("apt/${operatingsystem}/Hebex.list.erb"),
#               confdir => "${aptconfdir}",
#               require => [ File["$aptconfdir/sources.list.d"], Exec["confdir-${name}"] ],
#         }

         # create the pbuilder if it was not created yet
         exec { "create_pbuilder_${name}":
            command  => "${script} create",
            timeout  => 0,
            creates  => $basetgz,
            require  => [ Package[pbuilder], 
                         File[$script], File[$aptconfdir],
                         File[$pbuilderrc], File[$builddir], File[$aptcachedir], 
                         Exec["chrootdir-${name}"]
                        ]
         }

         # update the pbuilder if the config changes but only if $basetgz exists
         exec { "update_pbuilder_${name}":
            command     => "${script} update --override-config",
            onlyif      => "/usr/bin/test -f ${basetgz}",
            subscribe   => [ File[$aptconfdir], File[$pbuilderrc] ],
            refreshonly => true,
            require  => [ Package[pbuilder],
                         File[$script], File[$aptconfdir],
                         File[$pbuilderrc], File[$builddir], File[$aptcachedir],
                         Exec["chrootdir-${name}"]
                        ]
         }
      }

      absent: {
         # clean pbuilder to be sure no proc/dev is mounted in $builddir
         exec { "clean_pbuilder_${name}":
            command => "${script} clean",
            onlyif  => "/usr/bin/test -f ${script}",
            require => Package[pbuilder]
         }

         file {
            # remove single files
            [ $script, $pbuilderrc, $basetgz]:
               require => Exec["clean_pbuilder_${name}"],
               ensure  => absent; 
            # recursively remove internal directories
            [ $aptconfdir, $builddir, $resultdir, $aptcachedir ]:
               require => Exec["clean_pbuilder_${name}"],
               ensure  => absent,
               recurse => true,
               force   => true;
            # recursively remove containing directories
            [ $pbuilder_confdir, $pbuilder_cachedir ]:
               require => [ Exec["clean_pbuilder_${name}"], 
                            File[$script], File[$pbuilderrc],
                            File[$aptconfdir],
                            File[$builddir], File[$resultdir], File[$aptcachedir]
                           ],
               ensure  => absent,
               force   => true;
         }
      }
   }

}

