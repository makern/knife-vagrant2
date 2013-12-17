require 'chef/knife/vagrant_base'

class Chef
  class Knife
    class VagrantServerCreate < Knife

      include Knife::VagrantBase
      deps do
        require 'ipaddr'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife vagrant server create (options)"

      option :box,
        :short => "-b BOX",
        :long => "--box BOX",
        :description => "The vagrant box to use for the server",
        :proc => Proc.new { |b| Chef::Config[:knife][:box] = b }

      option :box_url,
        :short => '-U URL',
        :long => '--box-url URL',
        :description => 'URL of pre-packaged vbox template. Can be a local path or an HTTP URL.',
        :proc => Proc.new { |b| Chef::Config[:knife][:box_url] = b }

      option :memsize,
        :short => '-m MEMORY',
        :long => '--memsize MEMORY',
        :description => 'Amount of RAM to allocate to provisioned VM, in MB. Defaults to 1024',
        :proc => Proc.new { |m| Chef::Config[:knife][:memsize] = m },
        :default => 1024

      option :share_folders,
        :short => '-F',
        :long => '--share-folders SHARES',
        :description => 'Comma separated list of share folders in the form of HOST_PATH::GUEST_PATH',
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :use_cachier,
        :short => '-C',
        :long => '--use-cachier',
        :description => 'Enables VM to use the vagrant-cachier plugin',
        :boolean => true,
        :default => false

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"
#        :proc => Proc.new { |key| Chef::Config[:knife][:chef_node_name] = key }

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "vagrant"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

      option :ssh_gateway,
        :short => "-w GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway server",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key }

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'chef-full'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d }

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) }

      option :secret,
        :short => "-s SECRET",
        :long => "--secret ",
        :description => "The secret key to use to encrypt data bag item values",
        :proc => lambda { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        :long => "--secret-file SECRET_FILE",
        :description => "A file containing the secret key to use to encrypt data bag item values",
        :proc => lambda { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :json_attributes,
        :short => "-j JSON",
        :long => "--json-attributes JSON",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) }

      option :subnet,
        :short => "-s SUBNET",
        :long => "--subnet SUBNET",
        :description => "Subnet from which to pick instance IP address. Default: 192.168.67/24",
        :proc => Proc.new { |key| Chef::Config[:knife][:subnet] = key }, 
        :default => '192.168.67.0/24'

      option :ip_address,
        :short => "-I IP-ADDRESS",
        :long => "--private-ip-address IP-ADDRESS",
        :description => "Use this IP address for the new instance"
#        :proc => Proc.new { |ip| Chef::Config[:knife][:ip_address] = ip }

      option :port_forward,
        :short => '-f PORTS',
        :long => '--port-forward PORTS',
        :description => "Comma separated list of HOST:GUEST ports to forward",
        :proc => lambda { |o| Hash[o.split(/,/).collect { |a| a.split(/:/) }] },
        :default => {}

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :vb_customize,
        :long => "--vb-customize VBOXMANAGE_COMMANDS",
        :description => "List of customize options for the virtualbox vagrant provider separated by ::"

      def run
        $stdout.sync = true
        validate!

        @server = create_server_def

        msg_pair("Instance name", @server.name)
        msg_pair("Instance IP", @server.ip_address)
        msg_pair("Box", @server.box || @server.box_url)

        if vagrant_instance_list.detect { |i| i[:name] == @server.name } 
            ui.error("Instance #{@server.name} already exists")
            exit 1
        end

        # Create Vagrant file for new instance
        print "\n#{ui.color("Launching instance", :magenta)}\n"
        write_vagrantfile
        vagrant_exec(@server.name, 'up')

        write_insecure_key
        print "\n#{ui.color("Waiting for sshd", :magenta)}"
        wait_for_sshd(@server.ip_address)

        print "\n#{ui.color("Bootstraping instance", :magenta)}\n"
        bootstrap_node(@server,@server.ip_address).run


        puts "\n"
        msg_pair("Instance Name", @server.name)
        msg_pair("Box", @server.box || @server.box_url)
        msg_pair("IP Address", @server.ip_address)
        msg_pair("Environment", locate_config_value(:environment) || '_default')
        msg_pair("Run List", (config[:run_list] || []).join(', '))
        msg_pair("JSON Attributes", config[:json_attributes]) unless !config[:json_attributes] || config[:json_attributes].empty?
      end

      def build_port_forwards(ports)
        ports.collect { |k, v| "config.vm.network :forwarded_port, host: #{k}, guest: #{v}" }.join("\n")
      end

      def build_vb_customize(customize)
        customize.split(/::/).collect { |k| "vb.customize [ #{k} ]" }.join("\n")
      end

      def build_shares(share_folders)
        share_folders.collect do |share|
          host, guest = share.chomp.split "::"
          "config.vm.synced_folder '#{host}', '#{guest}'"
        end.join("\n")
      end

      def write_vagrantfile
        additions = []
        if @server.use_cachier
          additions << 'config.cache.auto_detect = true' # enable vagarant-cachier
        end

        file = <<-EOF
Vagrant.configure("2") do |config|
  config.vm.box = "#{@server.box}"
  config.vm.box_url = "#{@server.box_url}"
  config.vm.hostname = "#{@server.name}"

  config.vm.network :private_network, ip: "#{@server.ip_address}"
  #{build_port_forwards(@server.port_forward)}

  #{build_shares(@server.share_folders)}
 
  config.vm.provider :virtualbox do |vb|
    vb.customize [ "modifyvm", :id, "--memory", #{@server.memsize} ]
    #{build_vb_customize(@server.vb_customize)}
  end
  
  config.vm.provider :vmware_fusion do |v|
     v.vmx["memsize"] = "#{@server.memsize}"
  end

  config.vm.provider :vmware_workstation do |v|
     v.vmx["memsize"] = "#{@server.memsize}"
  end

  #{additions.join("\n")}
end
        EOF
        file

        # Create folder and write Vagrant file
        instance_dir = File.join(locate_config_value(:vagrant_dir), @server.name)
        instance_file = File.join(instance_dir, 'Vagrantfile')
        ui.msg("Creating #{instance_file}")
        FileUtils.mkdir_p(instance_dir)
        File.open(instance_file, 'w') { |f| f.write(file) }
      end

      def bootstrap_node(server,ssh_host)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [ssh_host]
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:ssh_port] = config[:ssh_port]
        bootstrap.config[:ssh_gateway] = config[:ssh_gateway]
        bootstrap.config[:identity_file] = config[:identity_file] || File.join(locate_config_value(:vagrant_dir), 'insecure_key')
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server.ip
        bootstrap.config[:distro] = locate_config_value(:distro) || "chef-full"
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:host_key_verify] = config[:host_key_verify]

        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = locate_config_value(:environment)
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes) || {}
        bootstrap.config[:encrypted_data_bag_secret] = locate_config_value(:encrypted_data_bag_secret)
        bootstrap.config[:encrypted_data_bag_secret_file] = locate_config_value(:encrypted_data_bag_secret_file)
        bootstrap.config[:secret] = locate_config_value(:secret)
        bootstrap.config[:secret_file] = locate_config_value(:secret_file)
        # Modify global configuration state to ensure hint gets set by
        # knife-bootstrap
        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["vagrant"] ||= {} # Cargo Cult programming FTW?

        msg_pair("SSH User", bootstrap.config[:ssh_user])
        msg_pair("SSH identity file", bootstrap.config[:identity_file])
        bootstrap
      end

      def validate!
        unless locate_config_value(:box) || locate_config_value(:box_url)
          ui.error("You need to either specify --box or --box-url")
          exit 1
        end
      end

      def find_available_ip
        subnet = locate_config_value('subnet')
        IPAddr.new(subnet).to_range().each { |ip|
          # 192.168.3.0/24 should yield 192.168.3.2 through 192.168.3.254
          # 192.168.3.1 cannot be used because virtual box uses it for the router
          mask = IPAddr::IN4MASK ^ ip.instance_variable_get("@mask_addr")
          unless [0, 1, mask].include? (ip & mask) or vagrant_instance_list.detect { |i| i[:ip_address] == ip.to_s } 
            return ip.to_s
          end
        }
        ui.error("No unused IP address available in subnet #{subnet}")
        exit 1
      end

      def create_server_def
        server_def = {
          :box => locate_config_value(:box),
          :box_url => locate_config_value(:box_url),
          :memsize => locate_config_value(:memsize),
          :share_folders => config[:share_folders],
          :port_forward => config[:port_forward],
          :use_cachier => config[:use_cachier],
          :vb_customize => locate_config_value(:vb_customize)
        }

        # Get specified IP address for new instance or pick an unused one from the subnet pool.
        server_def[:ip_address] = config[:ip_address] || find_available_ip

        collision = vagrant_instance_list.detect { |i| i[:ip_address] == server_def[:ip_address] }
        if collision
          ui.error("IP address #{server_def[:ip_address]} already in use by instance #{collision[:name]}")
          exit 1
        end

        # Derive name for vagrant instance from chef node name or IP
        server_def[:name] = locate_config_value(:chef_node_name) || server_def[:ip_address]

        # Turn it into and object like thing
        OpenStruct.new(server_def)
      end

      def wait_for_sshd(hostname)
        config[:ssh_gateway] ? wait_for_tunnelled_sshd(hostname) : wait_for_direct_sshd(hostname, config[:ssh_port])
      end

      def wait_for_tunnelled_sshd(hostname)
        print(".")
        print(".") until tunnel_test_ssh(hostname) {
          sleep @initial_sleep_delay ||= 2
          puts("done")
        }
      end

      def tunnel_test_ssh(hostname, &block)
        gw_host, gw_user = config[:ssh_gateway].split('@').reverse
        gw_host, gw_port = gw_host.split(':')
        gateway = Net::SSH::Gateway.new(gw_host, gw_user, :port => gw_port || 22)
        status = false
        gateway.open(hostname, config[:ssh_port]) do |local_tunnel_port|
          status = tcp_test_ssh('localhost', local_tunnel_port, &block)
        end
        status
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      end

      def wait_for_direct_sshd(hostname, ssh_port)
        print(".") until tcp_test_ssh(hostname, ssh_port) {
          sleep @initial_sleep_delay ||= 2
          puts("done")
        }
      end

      def tcp_test_ssh(hostname, ssh_port)
        tcp_socket = TCPSocket.new(hostname, ssh_port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      # This happens on some mobile phone networks
      rescue Errno::ECONNRESET
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

    end
  end
end
