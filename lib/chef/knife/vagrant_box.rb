require 'chef/knife/vagrant_base'

class Chef
  class Knife

    class VagrantBoxList < Knife
      include Knife::VagrantBase
      banner "knife vagrant box list"
      def run
        vagrant_exec('.', 'box list', no_cwd_change: true)
      end
    end

  end
end
