require 'require_all'

module ProjectYaML
  class Point < ProjectYaML::Object
    include(ProjectYaML::Logging)

    attr_accessor :name
    attr_accessor :description
    attr_accessor :type
    attr_accessor :geo
    attr_accessor :images
    attr_accessor :checkin_cn
    attr_accessor :req_metadata_hash

    def initialize(hash)
      super()
      @name = nil
      @images = []
      @geo = []
      @description = nil
      @noun = "point"
      @checkin_cn = 0
      @_namespace = :point
      from_hash(hash) unless hash == nil
    end

    def print_header
      return "Name", "Type", "Checkins", "Images", "UUID"
    end

    def print_items
      return @name, @type, @checkin_cn.to_s, @images.size.to_s, @uuid
    end

    def print_item
      return @name, @type, @description, @checkin_cn.to_i, "[#{@images.join(',')}]", @uuid
    end

    def print_item_header
      return "Name", "Type", "Description", "Checkins", "Images", "UUID"
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
