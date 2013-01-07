# Class: cobbler
#
# This class manages Cobbler
# https://fedorahosted.org/cobbler/
#
# Parameters:
#
#   - $service_name [type: string]
#     Name of the cobbler service, defaults to 'cobblerd'.
#
#   - $package_name [type: string]
#     Name of the installation package, defaults to 'cobbler'
#
#   - $package_ensure [type: string]
#     Defaults to 'present', buy any version can be set
#
#   - $distro_path [type: string]
#     Defines the location on disk where distro files will be
#     stored. Contents of the ISO images will be copied over
#     in these directories, and also kickstart files will be
#     stored. Defaults to '/distro'
#
#   - $manage_dhcp [type: bool]
#     Wether or not to manage ISC DHCP.
#
#   - $dhcp_dynamic_range [type: string]
#     Range for DHCP server
#
#   - $manage_dns [type: string]
#     Wether or not to manage DNS
#
#   - $dns_option [type: string]
#     Which DNS deamon to manage - Bind or dnsmasq. If dnsmasq,
#     then dnsmasq has to be used for DHCP too.
#
#   - $manage_tftpd [type: bool]
#     Wether or not to manage TFTP daemon.
#
#   - $tftpd_option [type:string]
#     Which TFTP daemon to use.
#
#   - $server_ip [type: string]
#     IP address of a server.
#
#   - $next_server_ip [type: string]
#     Next Server in cobbler config.
#
#   - $nameserversa [type: array]
#     Nameservers for kickstart files to put in resolv.conf upon
#     installation.
#
#   - $dhcp_interfaces [type: array]
#     Interface for DHCP to listen on.
#
#   - $defaultrootpw [type: string]
#     Hash of root password for kickstart files.
#
#   - $apache_service [type: string]
#     Name of the apache service.
#
#   - $allow_access [type: string]
#     For what IP addresses/hosts will access to cobbler_api be granted.
#     Default is for server_ip, ::ipaddress and localhost
#
#   - $purge_distro  [type: bool]
#   - $purge_repo    [type: bool]
#   - $purge_profile [type: bool]
#   - $purge_system  [type: bool]
#     Decides wether or not to purge (remove) from cobbler distro,
#     repo, profiles and systems which are not managed by puppet.
#     Default is true.
#
# Actions:
#   - Install Apache
#   - Manage Apache service
#
# Requires:
#   - puppetlabs/apache class
#     (http://forge.puppetlabs.com/puppetlabs/apache)
#
# Sample Usage:
#
class cobbler (
  $service_name       = $cobbler::params::service_name,
  $package_name       = $cobbler::params::package_name,
  $package_ensure     = $cobbler::params::package_ensure,
  $distro_path        = $cobbler::params::distro_path,
  $manage_dhcp        = $cobbler::params::manage_dhcp,
  $dhcp_dynamic_range = $cobbler::params::dhcp_dynamic_range,
  $manage_dns         = $cobbler::params::manage_dns,
  $dns_option         = $cobbler::params::dns_option,
  $manage_tftpd       = $cobbler::params::manage_tftpd,
  $tftpd_option       = $cobbler::params::tftpd_option,
  $server_ip          = $cobbler::params::server_ip,
  $next_server_ip     = $cobbler::params::next_server_ip,
  $nameservers        = $cobbler::params::nameservers,
  $dhcp_interfaces    = $cobbler::params::dhcp_interfaces,
  $defaultrootpw      = $cobbler::params::defaultrootpw,
  $apache_service     = $cobbler::params::apache_service,
  $allow_access       = $cobbler::params::allow_access,
  $purge_distro       = $cobbler::params::purge_distro,
  $purge_repo         = $cobbler::params::purge_repo,
  $purge_profile      = $cobbler::params::purge_profile,
  $purge_system       = $cobbler::params::purge_system,
) inherits cobbler::params {

  # require apache modules
  require apache::mod::wsgi
  require apache::mod::proxy
  require apache::mod::proxy_http

  # install section
  package { 'tftp-server': ensure => present, }
  package { 'syslinux':    ensure => present, }
  package { $package_name :
    ensure  => $package_ensure,
    require => [ Package['syslinux'], Package['tftp-server'], ],
  }

  service { $service_name :
    ensure  => running,
    enable  => true,
    require => Package[$package_name],
  }

  # file defaults
  File {
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0644',
  }
  file { '/etc/httpd/conf.d/proxy_cobbler.conf':
    content => template('cobbler/proxy_cobbler.conf.erb'),
    notify  => Service[$apache_service],
  }
  file { $distro_path :
    ensure => directory,
    mode   => '0755',
  }
  file { "${distro_path}/kickstarts" :
    ensure => directory,
    mode   => '0755',
  }
  file { '/etc/cobbler/settings':
    content => template('cobbler/settings.erb'),
    require => Package[$package_name],
    notify  => Service[$service_name],
  }
  file { '/etc/cobbler/modules.conf':
    content => template('cobbler/modules.conf.erb'),
    require => Package[$package_name],
    notify  => Service[$service_name],
  }
  file { '/etc/httpd/conf.d/distros.conf': content => template('cobbler/distros.conf.erb'), }
  file { '/etc/httpd/conf.d/cobbler.conf': content => template('cobbler/cobbler.conf.erb'), }

  # cobbler sync command
  exec { 'cobblersync':
    command     => '/usr/bin/cobbler sync',
    refreshonly => true,
  }

  # purge resources
  if $purge_distro == true {
    resources { 'cobblerdistro':  purge => true, }
  }
  if $purge_repo == true {
    resources { 'cobblerrepo':    purge => true, }
  }
  if $purge_profile == true {
    resources { 'cobblerprofile': purge => true, }
  }
  if $purge_system == true {
    resources { 'cobblersystem':  purge => true, }
  }

  # include ISC DHCP only if we choose manage_dhcp
  if $manage_dhcp == '1' {
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
      require => Package[$package_name],
      notify  => Exec['cobblersync'],
    }
  }
}
# vi:nowrap:
