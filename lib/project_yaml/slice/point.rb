require "json"


# Root ProjectYaML namespace
module ProjectYaML
  class Slice

    # ProjectYaML Slice Point
    class Point < ProjectYaML::Slice
      def initialize(args)
        super(args)
        @hidden          = false
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set of
        # commands that are typical for most slices)
        commands = get_command_map(
          "point_help",
          "get_all_points",
          "get_point_by_uuid",
          "add_point",
          "update_point",
          "remove_all_point",
          "remove_point_by_uuid")

        commands
      end

      def point_help
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
        puts "point Slice: used to view points and to remove points.".red
        puts "point Commands:".yellow
        puts "\tyaml point [get] [all]                      " + "View all points".yellow
        puts "\tyaml point [get] (UUID)                     " + "View specific point (log)".yellow
        puts "\tyaml point add (options...)                 " + "Create a new point".yellow
        puts "\tyaml point update (UUID) (options...)       " + "Update an existing point".yellow
        puts "\tyaml point remove (UUID)|all                " + "Remove existing (or all) point(s)".yellow
        puts "\tyaml point --help|-h                        " + "Display this screen".yellow
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
            { :name        => :description,
              :short_form  => '-d',
              :long_form   => '--description DESCRIPTION',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
            { :name        => :type,
              :short_form  => '-t',
              :long_form   => '--type TYPE',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
            { :name        => :geo,
              :short_form  => '-g',
              :long_form   => '--geo GEO',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
          ],
          :update  =>  [
            { :name        => :checkin_cn,
              :default     => nil,
              :short_form  => '-c',
              :long_form   => '--checkin CHECKIN',
              :uuid_is     => 'required',
              :required    => true
            },
            { :name        => :image,
              :default     => nil,
              :short_form  => '-i',
              :long_form   => '--image IMAGE',
              :uuid_is     => 'required',
              :required    => true
            },
          ]
        }
      end

      def get_all_points
        @command = :get_all_points
        # if it's a web command and the last argument wasn't the string "default" or "get", then a
        # filter expression was included as part of the web command
        @command_array.unshift(@prev_args.pop) if @web_command && @prev_args.peek(0) != "default" && @prev_args.peek(0) != "get"
        # Get all active model instances and print/return
        print_object_array get_object("points", :point), "Points:", :success_type => :generic, :style => :table
      end

      def get_point_by_uuid
        @command = :get_point_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        point = get_object("point_instance", :point, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find point with UUID: [#{uuid}]" unless point && (point.class != Array || point.length > 0)
        print_object_array [point], "", :success_type => :generic
      end

      def remove_all_points
        raise ProjectYaML::Error::Slice::MethodNotAllowed, "Cannot remove all points via REST" if @web_command
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove all points" unless get_data.delete_all_objects(:point)
        slice_success("All points removed", :success_type => :removed)
      end

      def remove_point_by_uuid
        @command = :remove_point_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        point = get_object("point_instance", :point, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find point with UUID: [#{uuid}]" unless point && (point.class != Array || point.length > 0)
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove point [#{point.uuid}]" unless get_data.delete_object(point)
        slice_success("point #{point.uuid} removed", :success_type => :removed)
      end

      def add_point
        @command = :add_point
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "yaml point add (options...)", :require_all)
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)

        point = ProjectYaML::Point.new({})

        # use the arguments passed in (above) to create a new model
        if @web_command
          raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Required Metadata [req_metadata_hash]" unless
              req_metadata_hash
          point.web_create_metadata(req_metadata_hash)
        end

        point.name        = options[:name]
        point.description = options[:description]
        point.type        = options[:type]
        point.geo         = options[:geo]
        point.geo = options[:geo].split(',')

        @data.persist_object(point)
        point ? print_object_array([point], "point created", :success_type => :created) : raise(ProjectYaML::Error::Slice::CouldNotCreate, "Could not create point")
      end

      def update_point
        @command = :update_point
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        point_uuid, options = parse_and_validate_options(option_items, "razor point update UUID (options...)", :require_one)
        includes_uuid = true if point_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        point = get_object("point_with_uuid", :point, point_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid point UUID [#{point_uuid}]" unless point && (point.class != Array || point.length > 0)

        # Update object properties
        point.checkin_cn = options[:checkin_cn] if options[:checkin_cn]
        point.images.push options[:image] if options[:image]

        # Update object
        raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update [#{point.uuid}]" unless point.update_self
        print_object_array [point], "", :success_type => :updated
      end
    end
  end
end


