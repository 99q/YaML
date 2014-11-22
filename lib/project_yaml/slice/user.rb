require "json"


# Root ProjectYaML namespace
module ProjectYaML
  class Slice

    # ProjectYaML Slice User
    class User < ProjectYaML::Slice
      def initialize(args)
        super(args)
        @hidden          = false
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set of
        # commands that are typical for most slices)
        commands = get_command_map(
          "user_help",
          "get_all_users",
          "get_user_by_uuid",
          "add_user",
          "update_user",
          "remove_all_user",
          "remove_user_by_uuid")

        commands
      end

      def user_help
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
        puts "User Slice: used to view users and to remove users.".red
        puts "User Commands:".yellow
        puts "\tyaml user [get] [all]                      " + "View all users".yellow
        puts "\tyaml user [get] (UUID)                     " + "View specific user (log)".yellow
        puts "\tyaml user add (options...)                 " + "Create a new user".yellow
        puts "\tyaml user update (UUID) (options...)       " + "Update an existing user".yellow
        puts "\tyaml user remove (UUID)|all                " + "Remove existing (or all) user(s)".yellow
        puts "\tyaml user --help|-h                        " + "Display this screen".yellow
      end

      def all_command_option_data
        {
          :add  =>  [
            { :name        => :name,
              :default     => nil,
              :short_form  => '-n',
              :long_form   => '--name NAME',
              :description => 'The name of user.',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
            { :name        => :gender,
              :default     => nil,
              :short_form  => '-g',
              :long_form   => '--gender GENDER',
              :description => 'The gender of user.',
              :uuid_is     => 'not_allowed',
              :required    => true
            },
            { :name        => :birth,
              :default     => nil,
              :short_form  => '-b',
              :long_form   => '--birth BIRTH',
              :description => 'The birthday of user.',
              :uuid_is     => 'not_allowed',
              :required    => false
            },
          ],
          :update  =>  [
            { :name        => :score,
              :default     => nil,
              :short_form  => '-s',
              :long_form   => '--score SCORE',
              :description => 'The score of user.',
              :uuid_is     => 'required',
              :required    => true
            },
            { :name        => :yaml,
              :default     => nil,
              :short_form  => '-y',
              :long_form   => '--yaml YAML',
              :description => 'The completed yaml of user.',
              :uuid_is     => 'required',
              :required    => true
            },
            { :name        => :cyaml,
              :default     => nil,
              :short_form  => '-c',
              :long_form   => '--current_yaml current_yaml',
              :description => 'The current yaml activity of user.',
              :uuid_is     => 'required',
              :required    => true
            },
            { :name        => :like,
              :default     => nil,
              :short_form  => '-l',
              :long_form   => '--like LIKE-IMAGE',
              :description => 'Images liked by user.',
              :uuid_is     => 'required',
              :required    => true
            },
            { :name        => :image,
              :default     => nil,
              :short_form  => '-i',
              :long_form   => '--image IMAGE',
              :description => 'Images uploaded from user policy.',
              :uuid_is     => 'required',
              :required    => true
            },
          ]
        }
      end

      def get_all_users
        @command = :get_all_uers
        # if it's a web command and the last argument wasn't the string "default" or "get", then a
        # filter expression was included as part of the web command
        @command_array.unshift(@prev_args.pop) if @web_command && @prev_args.peek(0) != "default" && @prev_args.peek(0) != "get"
        # Get all active model instances and print/return
        print_object_array get_object("users", :user), "Users:", :success_type => :generic, :style => :table
      end

      def get_user_by_uuid
        @command = :get_user_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        user = get_object("user_instance", :user, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find User with UUID: [#{uuid}]" unless user && (user.class != Array || user.length > 0)
        print_object_array [user], "", :success_type => :generic
      end

      def remove_all_users
        raise ProjectYaML::Error::Slice::MethodNotAllowed, "Cannot remove all Users via REST" if @web_command
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove all users" unless get_data.delete_all_objects(:user)
        slice_success("All users removed", :success_type => :removed)
      end

      def remove_user_by_uuid
        @command = :remove_user_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        user = get_object("user_instance", :user, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find User with UUID: [#{uuid}]" unless user && (user.class != Array || user.length > 0)
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove user [#{user.uuid}]" unless get_data.delete_object(user)
        slice_success("User #{user.uuid} removed", :success_type => :removed)
      end

      def add_user
        @command = :add_user
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "yaml user add (options...)", :require_all)
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)

        user = ProjectYaML::User.new({})

        # use the arguments passed in (above) to create a new model
        if @web_command
          raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Required Metadata [req_metadata_hash]" unless
              req_metadata_hash
          user.web_create_metadata(req_metadata_hash)
        end

        user.name   = options[:name]
        user.gender = options[:gender]
        user.birth  = options[:birth] if options[:birth]

        @data.persist_object(user)
        user ? print_object_array([user], "User created", :success_type => :created) : raise(ProjectYaML::Error::Slice::CouldNotCreate, "Could not create User")
      end

      def update_user
        @command = :update_user
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        user_uuid, options = parse_and_validate_options(option_items, "razor user update UUID (options...)", :require_one)
        includes_uuid = true if user_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        user = get_object("user_with_uuid", :user, user_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid User UUID [#{user_uuid}]" unless user && (user.class != Array || user.length > 0)

        # Update object properties
        user.score = options[:score] if options[:score]
        user.like_images.push options[:like] if options[:like]
        user.yamls.push options[:yaml] if options[:yaml]
        user.image.push options[:image] if options[:image]
        user.current_yaml = options[:current_yaml] if options[:current_yaml]

        # Update object
        raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update [#{user.uuid}]" unless user.update_self
        print_object_array [user], "", :success_type => :updated
      end
    end
  end
end


