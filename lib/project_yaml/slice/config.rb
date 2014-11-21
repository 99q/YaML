require "json"
require "yaml"

# Root ProjectYaML namespace
module ProjectYaML
  class Slice
    # ProjectYaML Slice Boot
    # Used for all boot logic by node
    class Config < ProjectYaML::Slice
      include(ProjectYaML::Logging)
      # Initializes ProjectYaML::Slice::Model including #slice_commands, #slice_commands_help
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = true
      end

      def slice_commands
        # Here we create a hash of the command string to the method it
        # corresponds to for routing.
        { :read    => "read_config",
          :dbcheck => "db_check",
          :default => :read,
          :else    => :read }
      end

      def db_check
        raise ProjectYaML::Error::Slice::MethodNotAllowed, "This method cannot be invoked via REST" if @web_command
        puts get_data.persist_ctrl.is_connected?
      end

      def read_config
        if @web_command # is this a web command
          print ProjectYaML.config.to_hash.to_json
        else
          puts "ProjectYaML Config:"
          ProjectYaML.config.to_hash.each do
          |key,val|
            print "\t#{key.sub("@","")}: ".white
            print "#{val} \n".green
          end
        end
      end

    end
  end
end
