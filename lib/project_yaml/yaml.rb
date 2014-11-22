require 'require_all'

module ProjectYaML
  class YaML < ProjectYaML::Object
    include(ProjectYaML::Logging)

    attr_accessor :user
    attr_accessor :route
    attr_accessor :current_point
    attr_accessor :next_point
    attr_accessor :checkin_points
    attr_accessor :completed
    attr_accessor :score
    attr_accessor :timestamp
    attr_accessor :req_metadata_hash

    def initialize(hash)
      super()
      @timestamp = Time.now.to_i
      @user
      @route = nil
      @current_point = nil
      @next_point = nil
      @checkin_points = {}
      @completed = false
      @score = 0
      @noun = "yaml"
      @_namespace = :yaml
      from_hash(hash) unless hash == nil
    end

    def print_header
      return "User", "Timestamp", "Route", "Current Point", "Next Point", "State", "UUID"
    end

    def print_items
      if @completed
        return @user.name, Time.at(@timestamp).to_s, @route.name, 'n/a', 'n/a', 'done', @uuid
      else
        current_point_str = @current_point ? @current_point : 'n/a'
        next_point_str = @next_point ? @next_point : 'n/a'
        return @user.name, Time.at(@timestamp).to_s, @route.uuid, current_point_str, next_point_str, 'doing', @uuid
      end
    end

    def print_item
      checkin_points_str = Array(@checkin_points.keys)
      if @completed
        return @user.name, Time.at(@timestamp).to_s, @route.uuid, 'n/a', 'n/a', checkin_points_str, @score,'done', @uuid
      else
        current_point = get_data.fetch_object_by_uuid(:point, @current_point)
        next_point = get_data.fetch_object_by_uuid(:point, @next_point)
        current_point_str = current_point ? current_point.name : 'n/a'
        next_point_str = next_point ? next_point.name : 'n/a'
        return @user.name, Time.at(@timestamp).to_s, @route.uuid, current_point_str, next_point_str, checkin_points_str, @score, 'doing', @uuid
      end
    end

    def print_item_header
      return "User", "Timestamp", "Route", "Current Point", "Next Point", "Checkin Points", "Score", "State", "UUID"
    end

    def line_color
      :white_on_black
    end

    def header_color
      :red_on_black
    end

    def config
      ProjectYaML.config
    end

    def web_create_metadata(provided_metadata)
      missing_metadata = []
      rmd = req_metadata_hash
      rmd.each_key do
        |md|
        metadata = map_keys_to_symbols(rmd[md])
        provided_metadata = map_keys_to_symbols(provided_metadata)
        md = (!md.is_a?(Symbol) ? md.gsub(/^@/,'').to_sym : md)
        md_fld_name = '@' + md.to_s
        if provided_metadata[md]
          raise ProjectYaML::Error::Slice::InvalidMetadata, "Invalid Metadata [#{md.to_s}:'#{provided_metadata[md]}']" unless
          set_metadata_value(md_fld_name, provided_metadata[md], metadata[:validation])
        else
          if metadata[:default] != ""
            raise ProjectYaML::Error::Slice::MissingMetadata, "Missing metadata [#{md.to_s}]" unless
            set_metadata_value(md_fld_name, metadata[:default], metadata[:validation])
          else
            raise ProjectRazor::Error::Slice::MissingMetadata, "Missing metadata [#{md.to_s}]" if metadata[:required]
          end
        end
      end
    end

  end
end
