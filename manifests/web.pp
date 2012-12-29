# Class: cobbler::web
#
# This module manages Cobbler
# https://fedorahosted.org/cobbler/
#
# Requires:
#   $cobbler_listen_ip be set in the nodes manifest, else defaults
#   to $ipaddress_eth1
#
class cobbler::web (
  $package_ensure = $cobbler::package_ensure,
) inherits cobbler {
  require apache::mod::ssl

  package { 'cobbler-web':
    ensure => $package_ensure,
  }
  file { '/etc/httpd/conf.d/cobbler_web.conf':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    require => [ Package['cobbler-web'], Class['apache'], ],
  }
}
