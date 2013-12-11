require 'chef/knife/ec2_base'

class Chef
  class Knife
    class VagrantServerList < Knife

      include Knife::VagrantBase

      banner "knife vagrant server list"

      def run
        $stdout.sync = true

        server_list = [
          ui.color('Instance Name', :bold),
          ui.color('IP Address', :bold),
          ui.color('Box', :bold),
          ui.color('Provider', :bold),
          ui.color('State', :bold)
        ].flatten.compact
        
        output_column_count = server_list.length
                
        vagrant_instance_list.each do |server|
          server_list << server[:name]
          server_list << server[:ip_address]
          server_list << server[:box]

          state, provider = vagrant_instance_state(server[:name])
          server_list << provider
          server_list << colored_vagrant_state(state)
        end

        puts ui.list(server_list, :uneven_columns_across, output_column_count)

      end
    end
  end
end
