class profiles::monitoring::client (
  String[1] $prometheus_username,
  String[1] $prometheus_password,
  Stdlib::HTTPUrl $prometheus_url,
  Array[Hash] $blackbox_targets = [],
) {
  if $facts['os']['family'] == 'RedHat' {
    yumrepo { 'copr:copr.fedorainfracloud.org:group_theforeman:infra':
      descr    => 'Copr repo for infra owned by @theforeman',
      baseurl  => 'https://download.copr.fedorainfracloud.org/results/@theforeman/infra/centos-stream-$releasever-$basearch/',
      gpgcheck => '1',
      gpgkey   => 'https://download.copr.fedorainfracloud.org/results/@theforeman/infra/pubkey.gpg',
      enabled  => '1',
      notify   => Package['node-exporter-textfile-collector-scripts'],
    }

    # node-exporter-textfile-collector-scripts needs moreutils, and that needs perl(IPC::Run) from CRB
    require crb

    # yum-utils contains /usr/bin/needs-restarting which is used by the yum collector
    stdlib::ensure_packages(['node-exporter-textfile-collector-scripts', 'yum-utils'])

    service { 'prometheus-node-exporter-yum.timer':
      ensure  => 'running',
      enable  => true,
      require => Package['node-exporter-textfile-collector-scripts'],
    }
  } elsif $facts['os']['family'] == 'Debian' {
    stdlib::ensure_packages(['prometheus-node-exporter-collectors'])
  }

  $prom_context = {
    'prometheus_username' => $prometheus_username,
    'prometheus_password' => $prometheus_password,
    'prometheus_url'      => $prometheus_url,
    'blackbox_targets'    => $blackbox_targets,
  }

  class { 'grafana_alloy':
    config => epp("${module_name}/monitoring/alloy-config.epp", $prom_context),
  }
}
