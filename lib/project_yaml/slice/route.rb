require "json"


# Root ProjectYaML namespace
module ProjectYaML
  class Slice

    # ProjectYaML Slice Route
    class Route < ProjectYaML::Slice
      def initialize(args)
        super(args)
        @hidden          = false
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set of
        # commands that are typical for most slices)
        commands = get_command_map(
          "route_help",
          "get_all_routes",
          "get_route_by_uuid",
          "add_route",
          nil,
          "remove_all_route",
          "remove_route_by_uuid")

        commands
      end

      def route_help
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
        puts "route Slice: used to view routes and to remove routes.".red
        puts "route Commands:".yellow
        puts "\tyaml route [get] [all]                      " + "View all routes".yellow
        puts "\tyaml route [get] (UUID)                     " + "View specific route (log)".yellow
        puts "\tyaml route add (options...)                 " + "Create a new route".yellow
        puts "\tyaml route remove (UUID)|all                " + "Remove existing (or all) route(s)".yellow
        puts "\tyaml route --help|-h                        " + "Display this screen".yellow
      end

      def all_command_option_data
        {
          :add  =>  [
            { :name        => :name,
              :short_form  => '-n',
              :long_form   => '--name NAME',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
            { :name        => :theme,
              :short_form  => '-t',
              :long_form   => '--theme THEME',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
            { :name        => :points,
              :short_form  => '-p',
              :long_form   => '--points POINTS',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
            { :name        => :description,
              :short_form  => '-d',
              :long_form   => '--description DESCRIPTION',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
          ],
        }
      end

      def get_all_routes
        @command = :get_all_routes
        # if it's a web command and the last argument wasn't the string "default" or "get", then a
        # filter expression was included as part of the web command
        @command_array.unshift(@prev_args.pop) if @web_command && @prev_args.peek(0) != "default" && @prev_args.peek(0) != "get"
        # Get all active model instances and print/return
        print_object_array get_object("routes", :route), "routes:", :success_type => :generic, :style => :table
      end

      def get_route_by_uuid
        @command = :get_route_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        route = get_object("route_instance", :route, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find route with UUID: [#{uuid}]" unless route && (route.class != Array || route.length > 0)
        print_object_array [route], "", :success_type => :generic
      end

      def remove_all_routes
        raise ProjectYaML::Error::Slice::MethodNotAllowed, "Cannot remove all routes via REST" if @web_command
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove all routes" unless get_data.delete_all_objects(:route)
        slice_success("All routes removed", :success_type => :removed)
      end

      def remove_route_by_uuid
        @command = :remove_route_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        route = get_object("route_instance", :route, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find route with UUID: [#{uuid}]" unless route && (route.class != Array || route.length > 0)
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove route [#{route.uuid}]" unless get_data.delete_object(route)
        slice_success("route #{route.uuid} removed", :success_type => :removed)
      end

      def add_route
        @command = :add_route
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "yaml route add (options...)", :require_all)
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)

        route = ProjectYaML::Route.new({})

        # use the arguments passed in (above) to create a new model
        if @web_command
          raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Required Metadata [req_metadata_hash]" unless
              req_metadata_hash
          route.web_create_metadata(req_metadata_hash)
        end

        route.description = options[:description]
        route.name = options[:name]
        route.theme = options[:theme]
        route.points  = Array(options[:points].split(','))

        @data.persist_object(route)
        route ? print_object_array([route], "route created", :success_type => :created) : raise(ProjectYaML::Error::Slice::CouldNotCreate, "Could not create route")
      end
    end
  end
end


