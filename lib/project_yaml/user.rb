require 'require_all'

module ProjectYaML
  class User < ProjectYaML::Object
    include(ProjectYaML::Logging)

    attr_accessor :name
    attr_accessor :label
    attr_accessor :gender
    attr_accessor :birth
    attr_accessor :rank
    attr_accessor :point
    attr_accessor :routes
    attr_accessor :req_metadata_hash

    def initialize(hash)
      super()
      @rank = 0
      @point = 0
      @gender = 'male'
      @birth = Date.new(1987, 10, 1).to_time.to_i
      @noun = "user"
      @routes = []
      @label = nil
      @noun = "user"
      @_namespace = :user
      from_hash(hash) unless hash == nil
    end

    def print_header
      return "Label", "Rank", "Point", "Routes", "Age", "UUID"
    end

    def print_item
      return @label, @rank.to_s, @point.to_s, @routes.size.to_s, age, @uuid
    end

    def print_item_header
      return "Label", "Rank", "Point", "Routes", "Age", "UUID"
    end

    def print_items
      return @label, @rank.to_s, @point.to_s, "[#{@routes.join(',')}]", age, @uuid
    end

    def line_color
      :white_on_black
    end

    def header_color
      :red_on_black
    end

    def age
      today = Date.today
      birthday = Time.at(@birth.to_i).to_datetime
      age = today.year - birthday.year
      age -= 1 if birthday.strftime("%m%d").to_i > today.strftime("%m%d").to_i
      age.to_s
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
          raise ProjectYaML::Error::Slice::InvalidUserMetadata, "Invalid Metadata [#{md.to_s}:'#{provided_metadata[md]}']" unless
          set_metadata_value(md_fld_name, provided_metadata[md], metadata[:validation])
        else
          if metadata[:default] != ""
            raise ProjectYaML::Error::Slice::MissingUserMetadata, "Missing metadata [#{md.to_s}]" unless
            set_metadata_value(md_fld_name, metadata[:default], metadata[:validation])
          else
            raise ProjectRazor::Error::Slice::MissingUserMetadata, "Missing metadata [#{md.to_s}]" if metadata[:required]
          end
        end
      end
    end

  end
end
