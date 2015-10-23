class cobbler::service {

  service { $cobbler::service_name :
    ensure  => running,
    enable  => true,
  }

}