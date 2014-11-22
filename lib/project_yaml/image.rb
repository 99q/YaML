require 'require_all'

module ProjectYaML
  class Image < ProjectYaML::Object
    include(ProjectYaML::Logging)

    attr_accessor :user_uuid
    attr_accessor :url
    attr_accessor :like_users
    attr_accessor :point_uuid
    attr_accessor :description
    attr_accessor :req_metadata_hash

    def initialize(hash)
      super()
      @user_uuid = nil
      @point_uuid = nil
      @description = nil
      @url = "http://qiniu.com/image/api/#{@uuid}"
      @noun = "image"
      @like_users = []
      @_namespace = :image
      from_hash(hash) unless hash == nil
    end

    def print_header
      return "Likes", "User UUID", "Point UUID", "UUID"
    end

    def print_items
      return @like_users.size.to_s, @user_uuid, @point_uuid, @uuid
    end

    def print_item
      point = get_data.fetch_object_by_uuid(:point, @point_uuid)
      user = get_data.fetch_object_by_uuid(:user, @user_uuid)
      user_str = user ? user.name : 'n/a'
      point_str = point ? point.name : 'n/a'
      geo_str = point ? point.geo : '[]'

      return "[#{@like_users.join(',')}]", user_str, point_str, geo_str, @uuid
    end

    def print_item_header
      return "Likes", "Owner", "Point", "Location", "UUID"
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
