class rbot::package {

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  case $::osfamily {
    RedHat:  { $packages = [ 'db4', 'db4-utils', 'gettext', 'gettext-devel'] }
    Debian:  { $packages = [ 'libdb-ruby1.8' ]
      package { 'gettext-ruby':
        ensure   => 'present',
        name     => 'gettext',
        provider => 'gem',
      }
    }
    default: { fail ("OS $::osfamily is not supported") }
  }

  $extra_gems = [ 'mechanize', 'tzinfo', 'tokyocabinet' ]

  package { $packages: ensure => 'present' }
  ->
  package { $extra_gems:
    ensure   => 'present',
    provider => 'gem',
  }
  ->
  exec { 'download-rbot':
    command => "wget --directory-prefix=/tmp http://ruby-rbot.org/download/rbot-${$rbot::version}.tgz",
    creates => "/tmp/rbot-${rbot::version}.tgz",
    unless  => "which ${rbot::working_dir}/setup.rb",
  }
  ->
  exec { 'extract-rbot':
    command => "tar zxf /tmp/rbot-${rbot::version}.tgz -C ${rbot::base_dir}",
    creates => $rbot::working_dir,
    unless  => "which ${rbot::working_dir}/setup.rb",
  }
  ->
  file { "/tmp/rbot-${rbot::version}.tgz":
    ensure  => absent,
  }
  ->
  file { "${rbot::base_dir}/rbot":
    ensure  => symlink,
    target  => "/opt/rbot-${rbot::version}",
  }
}
