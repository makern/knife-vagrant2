require 'chef/knife'

class Chef
  class Knife
    class VagrantServerUp < Knife

      include Knife::VagrantBase

      banner "knife vagrant server up SERVER [SERVER]"

      def run
        $stdout.sync = true

        @name_args.each do |instance|
          unless vagrant_instance_list.detect { |i| i[:name] == instance }
            ui.error("No instance named #{instance}")
            next            
          end

          state, provider = vagrant_instance_state(instance)

          unless state == 'poweroff'
            ui.error("Instance #{instance} needs to be powered off for up. Current state is #{colored_vagrant_state(state)}")
            next
          end

          vagrant_exec(instance, 'up')
        end
      end

    end
  end
end
