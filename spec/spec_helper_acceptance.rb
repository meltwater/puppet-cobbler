require 'beaker-rspec'

hosts.each do |host|
  # Install Puppet
  # if there is a specific version in the host yml use it - otherwise default to latest < 4.x
  install_puppet_on(host, {
    :version => host.host_hash["puppet_version"]
   })
end

### helper to use more than 1 host
def apply_on_all_hosts(pp)
  hosts.each do |host|
   apply_manifest_on(host, pp, :catch_failures => true)
   apply_manifest_on(host, pp, :catch_changes => true)
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Configure EPEL if appropriate.
    hosts.each do |host|
      # Install module
      copy_module_to(host, :source => proj_root, :module_name => 'cobbler')

      # Install dependencies
      on host, puppet('module','install','puppetlabs-apache'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
