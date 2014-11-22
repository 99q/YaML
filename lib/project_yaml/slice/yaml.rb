require "json"


# Root ProjectYaML namespace
module ProjectYaML
  class Slice

    # ProjectYaML Slice YaML
    class Yaml < ProjectYaML::Slice
      def initialize(args)
        super(args)
        @hidden          = false
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set of
        # commands that are typical for most slices)
        commands = get_command_map(
          "yaml_help",
          "get_all_yamls",
          "get_yaml_by_uuid",
          "add_yaml",
          "update_yaml",
          "remove_all_yaml",
          "remove_yaml_by_uuid")

        commands
      end

      def yaml_help
        if @prev_args.length > 1
          command = @prev_args.peek(1)
          begin
            # load the option items for this command (if they exist) and print them
            option_items = command_option_data(command)
            print_command_help(command, option_items)
            return
          rescue
          end
        end
        # if here, then either there are no specific options for the current command or we've
        # been asked for generic help, so provide generic help
        puts "yaml Slice: used to view yamls and to remove yamls.".red
        puts "yaml Commands:".yellow
        puts "\tyaml yaml [get] [all]                      " + "View all yamls".yellow
        puts "\tyaml yaml [get] (UUID)                     " + "View specific yaml (log)".yellow
        puts "\tyaml yaml add (options...)                 " + "Create a new yaml".yellow
        puts "\tyaml yaml remove (UUID)|all                " + "Remove existing (or all) yaml(s)".yellow
        puts "\tyaml yaml --help|-h                        " + "Display this screen".yellow
      end

      def all_command_option_data
        {
          :add  =>  [
            { :name        => :user_uuid,
              :short_form  => '-u',
              :long_form   => '--user_uuid USER_UUID',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
            { :name        => :route_uuid,
              :short_form  => '-r',
              :long_form   => '--route_uuid ROUTE_UUID',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
          ],
          :update  =>  [
            { :name        => :checkin_point,
              :short_form  => '-c',
              :long_form   => '--checkin_point CHECKIN_POINT',
              :uuid_is     => 'required',
              :required    => true
            },
          ],
        }
      end

      def get_all_yamls
        @command = :get_all_yamls
        # if it's a web command and the last argument wasn't the string "default" or "get", then a
        # filter expression was included as part of the web command
        @command_array.unshift(@prev_args.pop) if @web_command && @prev_args.peek(0) != "default" && @prev_args.peek(0) != "get"
        # Get all active model instances and print/return
        print_object_array get_object("yamls", :yaml), "yamls:", :success_type => :generic, :style => :table
      end

      def get_yaml_by_uuid
        @command = :get_yaml_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        yaml = get_object("yaml_instance", :yaml, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find yaml with UUID: [#{uuid}]" unless yaml && (yaml.class != Array || yaml.length > 0)
        print_object_array [yaml], "", :success_type => :generic
      end

      def remove_all_yamls
        raise ProjectYaML::Error::Slice::MethodNotAllowed, "Cannot remove all yamls via REST" if @web_command
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove all yamls" unless get_data.delete_all_objects(:yaml)
        slice_success("All yamls removed", :success_type => :removed)
      end

      def remove_yaml_by_uuid
        @command = :remove_yaml_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        yaml = get_object("yaml_instance", :yaml, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find yaml with UUID: [#{uuid}]" unless yaml && (yaml.class != Array || yaml.length > 0)
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove yaml [#{yaml.uuid}]" unless get_data.delete_object(yaml)
        slice_success("yaml #{yaml.uuid} removed", :success_type => :removed)
      end

      def add_yaml
        @command = :add_yaml
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "yaml yaml add (options...)", :require_all)
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)

        yaml = ProjectYaML::YaML.new({})

        # use the arguments passed in (above) to create a new model
        if @web_command
          raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Required Metadata [req_metadata_hash]" unless
              req_metadata_hash
          yaml.web_create_metadata(req_metadata_hash)
        end
        user = get_object("user_instance", :user, options[:user_uuid])
        route = get_object("route_instance", :route, options[:route_uuid])
        yaml.user = user if user
        yaml.route = route if route

        @data.persist_object(yaml)
        yaml ? print_object_array([yaml], "yaml created", :success_type => :created) : raise(ProjectYaML::Error::Slice::CouldNotCreate, "Could not create yaml")
      end

      def update_yaml
        @command = :update_yaml
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        yaml_uuid, options = parse_and_validate_options(option_items, "razor yaml update UUID (options...)", :require_one)
        includes_uuid = true if yaml_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        yaml = get_object("yaml_with_uuid", :yaml, yaml_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid yaml UUID [#{yaml_uuid}]" unless yaml && (yaml.class != Array || yaml.length > 0)

        # Update object properties
        if options[:checkin_point]
          if options[:checkin_point] == 'passport'
            if yaml.route
              yaml.route.points.each do
                |point|
                yaml.checkin_points[point] = Time.now.to_i
              end
              yaml.completed = true
              # TODO update Score
              yaml.score = 50 + Random.rand(50)
            end
          else
            yaml.checkin_points[options[:checkin_point]] = Time.now.to_i
            yaml.current_point = options[:checkin_point]
            if yaml.route
              index = yaml.route.points.index(options[:checkin_point])
              if index
                if index + 1 == yaml.route.points.size
                  yaml.completed = true
                  # TODO update Score
                  yaml.score = 50 + Random.rand(50)
                else
                  yaml.next_point = yaml.route.points[index + 1]
                end
              end
            end
          end
        end

        # Update object
        raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update [#{yaml.uuid}]" unless yaml.update_self
        print_object_array [yaml], "", :success_type => :updated
      end
    end
  end
end


