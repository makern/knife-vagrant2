require 'chef/knife'

class Chef
  class Knife
    module VagrantBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          option :vagrant_dir,
            :short => '-D PATH',
            :long => '--vagrant-dir PATH',
            :description => "Path to where Vagrant files are stored. Defaults to cwd/vagrant (#{Dir.pwd}/vagrant)",
            :proc => Proc.new { |key| Chef::Config[:knife][:vagrant_dir] = key },
            :default => File.join(Dir.pwd, '/vagrant')
        end
      end

      def vagrant_exec(instance, cmd, opts = {})
        fetch_output = opts[:fetch_output] || false
        no_cwd_change = opts[:no_cwd_change] || false

        unless no_cwd_change
          cwd = Dir.getwd()
          Dir.chdir(File.join(locate_config_value(:vagrant_dir), instance))
        end

        cmd = "vagrant #{cmd}"
        output = nil
        if defined? Bundler
          # Needed if we are run from inside a bundler environment and vagrant
          # is installed as global gem. If this causes problems for anyone please
          # file a bug report.
          Bundler.with_clean_env do
            output = fetch_output ? %x(#{cmd}) : system(cmd)
          end
        else
          output = fetch_output ? %x(#{cmd}) : system(cmd)
        end

        unless no_cwd_change
          Dir.chdir(cwd)
        end
        output
      end

      def vagrant_instance_state(instance)
        output = vagrant_exec(instance, 'status', fetch_output: true)
        state = /Current machine states:.+?default\s+(.+?)\s+\((.+?)\)/m.match(output)
        unless state
          ui.warn("Couldn't parse state of instance #{instance}")
          return ['', '']
        end
        return [state[1], state[2]]
      end

      def vagrant_instance_list
        # Memoize so we don't have to parse files multiple times
        if @vagrant_instances
          return @vagrant_instances
        end

        vangrant_dir = locate_config_value(:vagrant_dir)
        @vagrant_instances = []

        unless File.exist? vangrant_dir
          return @vagrant_instances
        end    

        Dir.foreach(vangrant_dir) { |subdir|
          vagrant_file = File.join(vangrant_dir, subdir, 'Vagrantfile')
          if File.exist? vagrant_file
            instance = { :name => subdir,
                         :vagrant_file => vagrant_file
                       }
            # Read settings from vagrant file
            content = IO.read(vagrant_file)
            instance[:ip_address] = /config\.vm\.network[^,]+,\s*ip:\s*"([0-9\.]+)"/.match(content) { |m| m[1] }
            unless instance[:ip_address]
              ui.warn("Couldn't find IP address in #{vagrant_file}. Is it malformed?")           
            end

            instance[:box] = /config\.vm\.box[^=]*=\s*"([^"]+)"/.match(content) { |m| m[1] }
            unless instance[:box]
              ui.warn("Couldn't find box in #{vagrant_file}. Is it malformed?")           
            end
            @vagrant_instances.push(instance)
          end
        }
        @vagrant_instances
      end

      def vagrant_version
        @vagrant_version ||= begin
          version = vagrant_exec('', '-v', { :no_cwd_change => true, :fetch_output => true })
          version = /Vagrant\s+([0-9\.]+)/.match(version) { |m| m[1] }
        end
      end

      def vagrant_version_cmp(version)
        Gem::Version.new(vagrant_version) <=> Gem::Version.new(version)
      end

      def write_insecure_key
        # The private key most vagrant boxes use.
        insecure_key = <<-EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzI
w+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoP
kcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2
hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NO
Td0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcW
yLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQIBIwKCAQEA4iqWPJXtzZA68mKd
ELs4jJsdyky+ewdZeNds5tjcnHU5zUYE25K+ffJED9qUWICcLZDc81TGWjHyAqD1
Bw7XpgUwFgeUJwUlzQurAv+/ySnxiwuaGJfhFM1CaQHzfXphgVml+fZUvnJUTvzf
TK2Lg6EdbUE9TarUlBf/xPfuEhMSlIE5keb/Zz3/LUlRg8yDqz5w+QWVJ4utnKnK
iqwZN0mwpwU7YSyJhlT4YV1F3n4YjLswM5wJs2oqm0jssQu/BT0tyEXNDYBLEF4A
sClaWuSJ2kjq7KhrrYXzagqhnSei9ODYFShJu8UWVec3Ihb5ZXlzO6vdNQ1J9Xsf
4m+2ywKBgQD6qFxx/Rv9CNN96l/4rb14HKirC2o/orApiHmHDsURs5rUKDx0f9iP
cXN7S1uePXuJRK/5hsubaOCx3Owd2u9gD6Oq0CsMkE4CUSiJcYrMANtx54cGH7Rk
EjFZxK8xAv1ldELEyxrFqkbE4BKd8QOt414qjvTGyAK+OLD3M2QdCQKBgQDtx8pN
CAxR7yhHbIWT1AH66+XWN8bXq7l3RO/ukeaci98JfkbkxURZhtxV/HHuvUhnPLdX
3TwygPBYZFNo4pzVEhzWoTtnEtrFueKxyc3+LjZpuo+mBlQ6ORtfgkr9gBVphXZG
YEzkCD3lVdl8L4cw9BVpKrJCs1c5taGjDgdInQKBgHm/fVvv96bJxc9x1tffXAcj
3OVdUN0UgXNCSaf/3A/phbeBQe9xS+3mpc4r6qvx+iy69mNBeNZ0xOitIjpjBo2+
dBEjSBwLk5q5tJqHmy/jKMJL4n9ROlx93XS+njxgibTvU6Fp9w+NOFD/HvxB3Tcz
6+jJF85D5BNAG3DBMKBjAoGBAOAxZvgsKN+JuENXsST7F89Tck2iTcQIT8g5rwWC
P9Vt74yboe2kDT531w8+egz7nAmRBKNM751U/95P9t88EDacDI/Z2OwnuFQHCPDF
llYOUI+SpLJ6/vURRbHSnnn8a/XG+nzedGH5JGqEJNQsz+xT2axM0/W/CRknmGaJ
kda/AoGANWrLCz708y7VYgAtW2Uf1DPOIYMdvo6fxIB5i9ZfISgcJ/bbCUkFrhoH
+vq/5CIWxCPp0f85R4qxxQ5ihxJ0YDQT9Jpx4TMss4PSavPaBH3RXow5Ohe+bYoQ
NE5OgEXk2wVfZczCZpigBKbKZHNYcelXtTt/nP3rsCuGcM4h53s=
-----END RSA PRIVATE KEY-----
        EOF
        insecure_key

        # Write key to vagrant folder if it's not there yet.
        key_file = File.join(locate_config_value(:vagrant_dir), 'insecure_key')
        unless File.exist? key_file
          ui.msg("Creating #{key_file}")
          FileUtils.mkdir_p(locate_config_value(:vagrant_dir))
          File.open(key_file, 'w') { |f| f.write(insecure_key) }
          File.chmod(0600, key_file)
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def colored_vagrant_state(state)
          case state
          when 'saved','paused','poweroff', 'stuck', 'aborted', 'gurumeditation', 'inaccessible'
            ui.color(state, :red)
          when 'saving'
            ui.color(state, :yellow)
          else
            ui.color(state, :green)
          end
      end

    end
  end
end


