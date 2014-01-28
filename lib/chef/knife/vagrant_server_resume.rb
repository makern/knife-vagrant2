require 'chef/knife/vagrant_base'

class Chef
  class Knife
    class VagrantServerResume < Knife

      include Knife::VagrantBase

      banner "knife vagrant server resume SERVER [SERVER]"

      def run
        $stdout.sync = true

        @name_args.each do |instance|
          unless vagrant_instance_list.detect { |i| i[:name] == instance }
            ui.error("No instance named #{instance}")
            next            
          end

          state, provider = vagrant_instance_state(instance)

          unless state == 'saved'
            ui.error("Instance #{instance} needs to be suspended for resume. Current state is #{colored_vagrant_state(state)}")
            next
          end

          vagrant_exec(instance, 'resume')
        end
      end

    end
  end
end
