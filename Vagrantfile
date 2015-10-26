# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # => vagrant plugin install vagrant-proxyconf
  if Vagrant.has_plugin?('vagrant-proxyconf')
    has_proxy = false
    if ENV.has_key?('http_proxy') and !ENV['http_proxy'].empty?
      config.proxy.http = ENV['http_proxy']
      has_proxy = true
    end
    if ENV.has_key?('https_proxy') and !ENV['https_proxy'].empty?
      config.proxy.https = ENV['https_proxy']
      has_proxy = true
    end
    if has_proxy
      config.proxy.no_proxy = 'localhost,127.0.0.1'
    end
  end

  config.vm.network "private_network", type: "dhcp"

  config.vm.synced_folder '.', '/etc/puppet/modules/cobbler/'

  config.vm.define 'centos-6' do |centos|
    centos.vm.box = 'puppetlabs/centos-6.6-64-puppet'
    centos.vm.provision 'shell', inline: 'puppet module install puppetlabs-apache'
    centos.vm.provision 'puppet' do |puppet|
      puppet.manifests_path = 'manifests'
      puppet.manifest_file = 'init.pp'
      puppet.options = [
          '--verbose',
          "-e 'class { cobbler: }'"
      ]
    end
  end

end
