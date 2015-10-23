class cobbler::install {

  package { 'tftp-server': ensure => present, }
  package { 'syslinux':    ensure => present, }

  package { $cobbler::package_name :
    ensure  => $cobbler::package_ensure,
  }
}

