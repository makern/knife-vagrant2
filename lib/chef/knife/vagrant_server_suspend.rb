require 'chef/knife'

class Chef
  class Knife
    class VagrantServerSuspend < Knife

      include Knife::VagrantBase

      banner "knife vagrant server suspend SERVER [SERVER]"

      def run
        $stdout.sync = true

        @name_args.each do |instance|
          unless vagrant_instance_list.detect { |i| i[:name] == instance }
            ui.error("No instance named #{instance}")
            next            
          end

          state, provider = vagrant_instance_state(instance)

          unless state == 'running'
            ui.error("Instance #{instance} needs to be running for suspend. Current state is #{colored_vagrant_state(state)}")
            next
          end

          vagrant_exec(instance, 'suspend')
        end
      end

    end
  end
end
