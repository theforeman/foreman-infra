# Calling this define will install Ruby in your default rbenv
# installs directory. Additionally, it can define the installed
# ruby as the global interpretter. It will install the bundler gem.
#
# @param install_dir
#   This is set when you declare the rbenv class. There is no
#   need to overrite it when calling the rbenv::build define.
#
# @param global
#   This is used to set the ruby to be the global interpreter.
#
# @param env
#   This is used to set environment variables when compiling ruby.
#
# @param rubygems_version
#  This is used to set a specific version of rubygems.
#
# @param bundler_version
#   This is used to set a specific version of bundler.
#
# @example Install Ruby 2.7.8 as global
#   rbenv::build { '2.7.8':
#     global => true,
#   }
#
define rbenv::build (
  Stdlib::Absolutepath $install_dir = $rbenv::install_dir,
  Boolean $global = false,
  Array[String[1]] $env = $rbenv::env,
  Optional[String] $rubygems_version = undef,
  Optional[String] $bundler_version = undef,
  Optional[String[1]] $user = $rbenv::user,
) {
  include rbenv

  $base_env = ["RBENV_ROOT=${install_dir}"]

  Exec {
    cwd     => $install_dir,
    timeout => 1800,
    path    => [
      "${install_dir}/bin/",
      "${install_dir}/shims/",
      '/bin/',
      '/sbin/',
      '/usr/bin/',
      '/usr/sbin/',
    ],
    user    => $user,
  }

  exec { "rbenv-install-${title}":
    command     => ['rbenv', 'install', $title],
    environment => $base_env + $env,
    creates     => "${install_dir}/versions/${title}",
    require     => Class['rbenv'],
  }

  if $rubygems_version {
    exec { "rubygems-${rubygems_version}":
      command     => "gem update --system ${rubygems_version}",
      environment => $base_env,
      require     => Exec["rbenv-install-${title}"],
      unless      => "gem --version | grep -q ${rubygems_version}",
    }

    # In case the rubygems version is set, it should be called before installing bundler. Otherwise you could run into
    # a series of issues like
    # https://bundler.io/blog/2019/05/14/solutions-for-cant-find-gem-bundler-with-executable-bundle.html.
    if $bundler_version {
      Exec["rubygems-${rubygems_version}"] -> Rbenv::Gem["bundler-${title}"]
    }
  }

  if $bundler_version {
    rbenv::gem { "bundler-${title}":
      gem          => 'bundler',
      ruby_version => $title,
      skip_docs    => true,
      version      => $bundler_version,
    }
  }

  if $global {
    exec { "rbenv-global-${title}":
      command     => ['rbenv', 'global', $title],
      environment => $base_env,
      require     => Exec["rbenv-install-${title}"],
      refreshonly => true,
    }
  }
}
