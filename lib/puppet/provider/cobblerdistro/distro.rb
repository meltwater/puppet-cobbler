require 'xmlrpc/client'
require 'fileutils'

Puppet::Type.type(:cobblerdistro).provide(:distro) do
  desc 'Support for managing the Cobbler distros'

  commands :wget    => '/usr/bin/wget',
           :mount   => '/bin/mount',
           :umount  => '/bin/umount',
           :cp      => '/bin/cp',
           :cobbler => '/usr/bin/cobbler'

  mk_resource_methods

  def self.instances
    keys = []
    # connect to cobbler server on localhost
    cobblerserver = XMLRPC::Client.new2('http://127.0.0.1/cobbler_api')
    # make the query (get all systems)
    xmlrpcresult = cobblerserver.call('get_distros')

    # get properties of current system to @property_hash
    xmlrpcresult.each do |member|
      keys << new(
        :name           => member['name'],
        :ensure         => :present,
        :arch           => member['arch'],
        :kernel         => member['kernel'],
        :initrd         => member['initrd'],
        :comment        => member['comment']
      )
    end
    keys
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  # sets architecture
  def arch=(value)
    cobbler('distro', 'edit', '--name=' + @resource[:name], '--arch=' + value.to_s)
    @property_hash[:arch]=(value.to_s)
  end

  # sets the path to kernel
  def kernel=(value)
    raise ArgumentError, 'correct kernel path must be specified!' unless File.exists?(value) 
    cobbler('distro', 'edit', '--name=' + @resource[:name], '--kernel=' + value)
    @property_hash[:kernel]=(value)
  end

  # sets the path to initrd
  def initrd=(value)
    raise ArgumentError, 'correct initrd path must be specified!' unless File.exists?(value) 
    cobbler('distro', 'edit', '--name=' + @resource[:name], '--initrd=' + value)
    @property_hash[:initrd]=(value)
  end

  # comment
  def comment=(value)
    cobbler('distro', 'edit', '--name=' + @resource[:name], '--comment=' + value)
    @property_hash[:comment]=(value)
  end

  def create
    # sanity check
    raise ArgumentError, 'destdir must be specified in cobblerdistro resource!' if @resource[:destdir].nil?

    # create destination directory for distro
    distrodestdir = @resource[:destdir] + '/' + @resource[:name]
    Dir.mkdir(distrodestdir) unless File.directory? distrodestdir

    # get ISO image
    wget(@resource[:isolink],'--continue','--directory-prefix=/tmp').strip

    # get ISO path
    isopath = '/tmp/' + @resource[:isolink].sub(/^.*\/(.*).iso/, '\1')

    # create mount destination
    if ! File.directory? isopath
      Dir.mkdir(isopath, 755)
    end
    mount( '-o', 'loop', isopath + '.iso', isopath)

    # real work to be done here
    currentdir = Dir.pwd
    Dir.chdir(isopath)
    cp('-R', '.', distrodestdir)
    Dir.chdir(currentdir)

    # clean garbage
    umount( '-f', isopath)
    Dir.delete(isopath)

    # after copying check for kernel and initrd
    raise ArgumentError, 'correct kernel path must be specified!' unless File.exists?(@resource[:kernel]) 
    raise ArgumentError, 'correct initrd path must be specified!' unless File.exists?(@resource[:initrd]) 

    # create profileargs variable
    cobblerargs = 'distro add --name=' + @resource[:name] + ' --kernel=' + @resource[:kernel] + ' --initrd=' + @resource[:initrd]
    # add distro to cobbler
    cobbler(cobblerargs.split(' '))

    # add properties
    self.arch    = @resource.should(:arch)    unless self.arch    == @resource.should(:arch)
    self.comment = @resource.should(:comment) unless self.comment == @resource.should(:comment)

    # final sync
    cobbler('sync')
    @property_hash[:ensure] = :present
  end

  def destroy
    # strap out distribution directory from kernel path
    distrodir = self.kernel.sub(/^(.*#{self.name}).*/, '\1')
    # if destdir is defined, override calculated value
    distrodir = @resource[:destdir] unless @resource[:destdir].nil?
    # sanity checks
    if !File.directory?(distrodir) or distrodir == '/' or distrodir.empty? or distrodir.nil?
      raise ArgumentError, 'Cannot remove cobbler distro: directory path incorrect. Please specify destdir.'
    end
    # remove distro
    FileUtils.rm_rf distrodir
    cobbler('distro','remove','--name=' + @resource[:name])
    cobbler('sync')
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end
end
