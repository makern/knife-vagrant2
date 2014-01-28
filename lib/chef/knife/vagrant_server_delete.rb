require 'chef/knife/vagrant_base'

# These two are needed for the '--purge' deletion case
require 'chef/node'
require 'chef/api_client'

class Chef
  class Knife
    class VagrantServerDelete < Knife

      include Knife::VagrantBase

      banner "knife vagrant server delete SERVER [SERVER] (options)"

      attr_reader :server

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the Vagrant node itself."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def run

        @name_args.each do |name|
          instance = vagrant_instance_list.detect { |i| i[:name] == name }
          unless instance
            ui.error("No instance named #{name}")
            next            
          end

          msg_pair("Instance Name", instance[:name])
          msg_pair("Box", instance[:box])
          msg_pair("Vagrant File", instance[:vagrant_file])
          msg_pair("IP Address", instance[:ip_address])

          puts "\n"
          confirm("Do you really want to delete this instance")

          vagrant_exec(instance[:name], 'destroy -f')
          instance_dir = File.join(locate_config_value(:vagrant_dir), instance[:name])
          FileUtils.rm_rf(instance_dir)

          ui.warn("Deleted instance #{instance[:name]}")

          if config[:purge]
            destroy_item(Chef::Node, instance[:name], "node")
            destroy_item(Chef::ApiClient, instance[:name], "client")
          else
            ui.warn("Corresponding node and client for the #{instance[:name]} instance were not deleted and remain registered with the Chef Server")
          end
        end
      end

    end
  end
end
