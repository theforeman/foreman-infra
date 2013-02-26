# uses a (slightly modified) 3rd-party pbuilder module to create
# tgz images of the specified OSs, as well as a hook script and an
# execution script. This can be use to build a package.
#
class debian {

  debian::pbuilder_setup {
    "squeeze64":
      ensure     => present,
      arch       => 'amd64',
      release    => 'squeeze',
      apturl     => 'http://ftp.de.debian.org/debian',
      aptcontent => "deb http://ftp.uk.debian.org/debian/ squeeze main non-free contrib\ndeb-src http://ftp.uk.debian.org/debian/ squeeze main non-free contrib\n";
    "squeeze32":
      ensure     => present,
      arch       => 'i386',
      release    => 'squeeze',
      apturl     => 'http://ftp.de.debian.org/debian',
      aptcontent => "deb http://ftp.uk.debian.org/debian/ squeeze main non-free contrib\ndeb-src http://ftp.uk.debian.org/debian/ squeeze main non-free contrib\n";
    "precise64":
      ensure     => present,
      arch       => 'amd64',
      release    => 'precise',
      apturl     => 'http://gb.archive.ubuntu.com/ubuntu',
      aptcontent => "deb http://gb.archive.ubuntu.com/ubuntu/ precise main restricted\ndeb-src http://gb.archive.ubuntu.com/ubuntu/ precise main restricted\n";
    "precise32":
      ensure     => present,
      arch       => 'i386',
      release    => 'precise',
      apturl     => 'http://gb.archive.ubuntu.com/ubuntu',
      aptcontent => "deb http://gb.archive.ubuntu.com/ubuntu/ precise main restricted\ndeb-src http://gb.archive.ubuntu.com/ubuntu/ precise main restricted\n";
  }

  # Add freight setup
  include freight

  # TODO: Cleanup failed pbuilder mounts as a cron

}
