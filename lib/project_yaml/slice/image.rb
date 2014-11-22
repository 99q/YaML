require "json"


# Root ProjectYaML namespace
module ProjectYaML
  class Slice

    # ProjectYaML Slice Image
    class Image < ProjectYaML::Slice
      def initialize(args)
        super(args)
        @hidden          = false
      end

      def slice_commands
        # get the slice commands map for this slice (based on the set of
        # commands that are typical for most slices)
        commands = get_command_map(
          "image_help",
          "get_all_images",
          "get_image_by_uuid",
          "add_image",
          "update_image",
          "remove_all_image",
          "remove_image_by_uuid")

        commands
      end

      def image_help
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
        puts "image Slice: used to view images and to remove images.".red
        puts "image Commands:".yellow
        puts "\tyaml image [get] [all]                      " + "View all images".yellow
        puts "\tyaml image [get] (UUID)                     " + "View specific image (log)".yellow
        puts "\tyaml image add (options...)                 " + "Create a new image".yellow
        puts "\tyaml image update (UUID) (options...)       " + "Update an existing image".yellow
        puts "\tyaml image remove (UUID)|all                " + "Remove existing (or all) image(s)".yellow
        puts "\tyaml image --help|-h                        " + "Display this screen".yellow
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
            { :name        => :point_uuid,
              :short_form  => '-p',
              :long_form   => '--point_uuid POINT_UUID',
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
          :update  =>  [
            { :name        => :like,
              :short_form  => '-l',
              :long_form   => '--like LIKE',
              :uuid_is     => 'required',
              :required    => true
            },
          ]
        }
      end

      def get_all_images
        @command = :get_all_images
        # if it's a web command and the last argument wasn't the string "default" or "get", then a
        # filter expression was included as part of the web command
        @command_array.unshift(@prev_args.pop) if @web_command && @prev_args.peek(0) != "default" && @prev_args.peek(0) != "get"
        # Get all active model instances and print/return
        print_object_array get_object("images", :image), "images:", :success_type => :generic, :style => :table
      end

      def get_image_by_uuid
        @command = :get_image_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        image = get_object("image_instance", :image, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find image with UUID: [#{uuid}]" unless image && (image.class != Array || image.length > 0)
        print_object_array [image], "", :success_type => :generic
      end

      def remove_all_images
        raise ProjectYaML::Error::Slice::MethodNotAllowed, "Cannot remove all images via REST" if @web_command
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove all images" unless get_data.delete_all_objects(:image)
        slice_success("All images removed", :success_type => :removed)
      end

      def remove_image_by_uuid
        @command = :remove_image_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        image = get_object("image_instance", :image, uuid)
        raise ProjectYaML::Error::Slice::InvalidUUID, "Cannot Find image with UUID: [#{uuid}]" unless image && (image.class != Array || image.length > 0)
        raise ProjectYaML::Error::Slice::CouldNotRemove, "Could not remove image [#{image.uuid}]" unless get_data.delete_object(image)
        slice_success("image #{image.uuid} removed", :success_type => :removed)
      end

      def add_image
        @command = :add_image
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "yaml image add (options...)", :require_all)
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)

        image = ProjectYaML::Image.new({})

        # use the arguments passed in (above) to create a new model
        if @web_command
          raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Required Metadata [req_metadata_hash]" unless
              req_metadata_hash
          image.web_create_metadata(req_metadata_hash)
        end

        image.description = options[:description]
        image.user_uuid        = options[:user_uuid]
        image.point_uuid         = options[:point_uuid]

        @data.persist_object(image)
        image ? print_object_array([image], "image created", :success_type => :created) : raise(ProjectYaML::Error::Slice::CouldNotCreate, "Could not create image")
      end

      def update_image
        @command = :update_image
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = command_option_data(:update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        image_uuid, options = parse_and_validate_options(option_items, "razor image update UUID (options...)", :require_one)
        includes_uuid = true if image_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        image = get_object("image_with_uuid", :image, image_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid image UUID [#{image_uuid}]" unless image && (image.class != Array || image.length > 0)

        # Update object properties
        image.like_users.push options[:like] if options[:like]

        # Update object
        raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update [#{image.uuid}]" unless image.update_self
        print_object_array [image], "", :success_type => :updated
      end
    end
  end
end


