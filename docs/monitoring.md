# Monitoring

The Foreman project uses a sponsored Grafana instance at https://theforeman.grafana.net for metrics and alerting

## Access

People who work on infrastructure can be added to the organization by Eric, Evgeni or Ewoud.

## Dashboards

- [Blackbox Exporter (HTTP Prober)](https://grafana.com/grafana/dashboards/13659-blackbox-exporter-http-prober/) shows HTTP status at https://theforeman.grafana.net/d/NEzutrbMk/blackbox-exporter-http-prober
- Restic Exporter shows backup status at https://theforeman.grafana.net/d/9f4a1fae-9438-41af-97f3-ca0f87f8ba3f/restic-exporter
- Various OS-level views can be seen at https://theforeman.grafana.net/dashboards/f/integration---linux-node/

## Alerting

### Contact points

Contact points in Grafana are "notification groups", that can use different integrations (like mail, Slack, etc) and targets (like mail address etc).

Right now only one contact point is defined: `grafana-default-email` - it sends email to Eric, Ewoud and Evgeni.

### Alert rules

#### pending package updates

When `apt_upgrades_pending` or `yum_upgrades_pending` is `> 0` an alert is sent to `grafana-default-email`

#### reboot required

When `node_reboot_required` is `> 0` an alert is sent to `grafana-default-email`

#### missing backup

When `time() - restic_snapshot_timestamp_seconds` is `> 90000` (= the last restic snapshot is older than 25h) an alert is sent to `grafana-default-email`

#### http status

When `probe_http_status_code` is `!= 200` an alert is sent to `grafana-default-email`
