class profiles::monitoring::client (
  String[1] $prometheus_username,
  String[1] $prometheus_password,
  Stdlib::HTTPUrl $prometheus_url = 'https://prometheus-prod-01-eu-west-0.grafana.net/api/prom/push',
  Array[Hash] $blackbox_targets = [],
) {
  if $facts['os']['family'] == 'RedHat' {
    yumrepo { 'copr:copr.fedorainfracloud.org:evgeni:node-exporter-textfile-collector-scripts':
      descr    => 'Copr repo for node-exporter-textfile-collector-scripts owned by evgeni',
      baseurl  => 'https://download.copr.fedorainfracloud.org/results/evgeni/node-exporter-textfile-collector-scripts/centos-stream-$releasever-$basearch/',
      gpgcheck => '1',
      gpgkey   => 'https://download.copr.fedorainfracloud.org/results/evgeni/node-exporter-textfile-collector-scripts/pubkey.gpg',
      enabled  => '1',
    }
    stdlib::ensure_packages(['moreutils', 'node-exporter-textfile-collector-scripts'])
  }

  if $facts['os']['family'] == 'Debian' {
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
