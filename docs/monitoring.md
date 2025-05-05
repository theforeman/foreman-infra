# Monitoring

The Foreman project uses a sponsored Grafana instance at https://theforeman.grafana.net for metrics and alerting

## Access

People who work on infrastructure can be added to the organization by Eric, Evgeni or Ewoud.

## Dashboards

- [Blackbox Exporter (HTTP Prober)](https://grafana.com/grafana/dashboards/13659-blackbox-exporter-http-prober/)

## Alerting

### Contact points

Contact points in Grafana are "notification groups", that can use different integrations (like mail, Slack, etc) and targets (like mail address etc).

Right now only one contact point is defined: `grafana-default-email` - it sends email to Eric, Ewoud and Evgeni.

### Alert rules

#### pending package updates

When `apt_upgrades_pending` or `yum_upgrades_pending` is `> 0` an alert is sent to `grafana-default-email`
