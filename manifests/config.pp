class cobbler::config {

  File {
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0644',
  }
  file { '/etc/httpd/conf.d/proxy_cobbler.conf':
    content => template('cobbler/proxy_cobbler.conf.erb'),
    notify  => Service[$cobbler::apache_service],
  }
  
  file { $cobbler::distro_path :
    ensure => directory,
    mode   => '0755',
  }
  file { "${cobbler::distro_path}/kickstarts" :
    ensure => directory,
    mode   => '0755',
  }
  file { '/etc/cobbler/settings':
    content => template('cobbler/settings.erb'),
    require => Package[$cobbler::package_name],
    notify  => Service[$cobbler::service_name],
  }
  file { '/etc/cobbler/modules.conf':
    content => template('cobbler/modules.conf.erb'),
    require => Package[$cobbler::package_name],
    notify  => Service[$cobbler::service_name],
  }
  file { '/etc/httpd/conf.d/distros.conf': content => template('cobbler/distros.conf.erb'), }
  file { '/etc/httpd/conf.d/cobbler.conf': content => template('cobbler/cobbler.conf.erb'), }

  # cobbler sync command
  exec { 'cobblersync':
    command     => '/usr/bin/cobbler sync',
    refreshonly => true,
  }

  # purge resources
  if $cobbler::purge_distro == true {
    resources { 'cobblerdistro':  purge => true, }
  }
  if $cobbler::purge_repo == true {
    resources { 'cobblerrepo':    purge => true, }
  }
  if $cobbler::purge_profile == true {
    resources { 'cobblerprofile': purge => true, }
  }
  if $cobbler::purge_system == true {
    resources { 'cobblersystem':  purge => true, }
  }

  # include ISC DHCP only if we choose manage_dhcp
  if $cobbler::manage_dhcp == '1' {
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
      require => Package[$cobbler::package_name],
      notify  => Exec['cobblersync'],
    }
  }
}