class cobbler::prerequisites {

  if $::osfamily == 'RedHat' {
    package { 'epel-release': ensure  => present, }
  }

}