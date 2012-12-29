# Class: cobbler::dhcp
#
# This module manages ISC DHCP for Cobbler
# https://fedorahosted.org/cobbler/
#
class cobbler::dhcp (
  $nameservers     = $cobbler::params::nameservers,
  $dhcp_interfaces = $cobbler::params::dhcp_interfaces
  ) inherits cobbler::params {
  package { 'dhcp':
    ensure => present,
  }
  service { 'dhcpd':
    ensure  => running,
    require => Package['dhcp'],
  }
  file { '/etc/cobbler/dhcp.template':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('cobbler/dhcp.template.erb'),
  }
}
