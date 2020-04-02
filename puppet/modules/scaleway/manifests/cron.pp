# Deploys a cronjob which calls the Scaleway API to
# snapshot a server. Does not need to be on the Scaleway host.
#
define scaleway::cron (
  String $api_key                   = 'NA',
  String $org_id                    = 'NA',
  Enum['present', 'absent'] $ensure = present,
) {
  file { "/etc/scaleway/${name}.yaml":
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0700', #root only, contains API keys
    content => "api_key: ${api_key}\norg_id: ${org_id}\n",
  }

  cron { "scaleway-snapshot-${name}":
    ensure  => $ensure,
    command => "/usr/bin/scaleway-snapshot ${name}",
    user    => root,
    hour    => '2',
    minute  => '0',
  }

}
