# Class: exim
#
# This module manages exim
#
# Joe Julian <me@joejulian.name>
# 2012-02-10
#
# Tested platforms:
#  - CentoOS 6.2
#
# Parameters:
#
# Actions:
#   Installs, configures, and manages the exim service.
#
# Requires:
#
# Sample Usage:
# include exim()
# include exim(version="latest", use_smarthost=true, smarthost_route_data="mymta.domain.dom")
#
#
# [Remember: No empty lines between comments and class definition]
class exim ($ensure="running",
            $version="installed",
            $primary_hostname="${::fqdn}",
            $domainlist_local_domains="@ : localhost : localhost.localdomain",
            $domainlist_relay_to_domains="",
            $hostlist_relay_from_hosts="127.0.0.1",
            $virus_scan=true,
            $av_scanner="clamd:/var/run/clamd.exim/clamd.sock",
            $spam_scan=false,
            $spamd_address="127.0.0.1 783",
            $tls_advertise_hosts="*",
            $tls_certificate="/etc/pki/tls/certs/exim.pem",
            $tls_privatekey="/etc/pki/tls/private/exim.pem",
            $daemon_smtp_ports="25 : 465 : 587",
            $tls_on_connect_ports = "465",
            $qualify_domain="",
            $qualify_recipient="",
            $allow_domain_literals=false,
            $never_users="root",
            $do_host_lookups=true,
            $host_lookup="*",
            $auth_advertise_hosts="",
            $rfc1413_hosts="*",
            $rfc1413_query_timeout="5s",
            $allow_unqualified_sender=false,
            $allow_unqualified_recipient=false,
            $allow_percent_hack=false,
            $percent_hack_domains="",
            $ignore_bounce_errors_after="2d",
            $timeout_frozen_after="7d",
            $split_spool_directory=false,
            $use_smarthost=false,
            $smarthost_driver="manualroute",
            $smarthost_domains="! +local_domains",
            $smarthost_transport="remote_smtp",
            $smarthost_route_data="",
            $use_gateway=false,
            $gateway_driver="manualroute",
            $gateway_transport="remote_smtp",
            $gateway_route_list="*",
            $gateway_auth_driver="smtp",
            $gateway_auth_hosts_try_auth="",
            $gateway_auth_username="",
            $gateway_auth_secret=""
        )
{
    if ! ($ensure in [ "running", "stopped" ]) {
        fail("ensure parameter must be running or stopped")
    }

    case $operatingsystem {
        debian, ubuntu: {
            $supported  = false
            $pkg_name   = [ "exim4" ]
            $svc_name   = "exim4"
            $config     = "/etc/exim4/exim.conf"
            notify { "${module_name}_unsupported":
                message => "The ${module_name} module is not yet supported on ${operatingsystem}",
            }
        }
        centos, redhat, oel, linux: {
            $supported  = true
            $pkg_name   = [ "exim" ]
            $svc_name   = "exim"
            $config     = "/etc/exim/exim.conf"
        }
        default: {
            $supported = false
            notify { "${module_name}_unsupported":
                message => "The ${module_name} module is not supported on ${operatingsystem}",
            }
        }
    }

    if ( $ensure == "running" ) {
        $enable = true
    } else {
        $enable = false
    }

    if ($supported == true) {
        package { $pkg_name:
            ensure => $version,
        }

        file { $config:
            ensure => present,
            require => Package[$pkg_name],
            content => template('exim/exim.conf.erb'),
            mode    => '0640',
            owner   => 'root',
            group   => 'mail',
        }

        service { "exim":
            ensure      => $ensure,
            enable      => $enable,
            name        => $svc_name,
            hasstatus   => true,
            hasrestart  => true,
            subscribe   => [ Package[$pkg_name], File[$config],],
        }
    }
}
