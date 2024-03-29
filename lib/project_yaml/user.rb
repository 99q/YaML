require 'require_all'

module ProjectYaML
  class User < ProjectYaML::Object
    include(ProjectYaML::Logging)

    attr_accessor :name
    attr_accessor :gender
    attr_accessor :birth
    attr_accessor :score
    attr_accessor :images
    attr_accessor :like_images
    attr_accessor :yamls
    attr_accessor :current_yaml
    attr_accessor :req_metadata_hash

    def initialize(hash)
      super()
      @score = 0
      @gender = 'male'
      @birth = Date.new(1987, 10, 1).to_time.to_i
      @images = []
      @like_images = []
      @yamls = []
      @current_yaml = nil
      @noun = "user"
      @_namespace = :user
      from_hash(hash) unless hash == nil
    end

    def print_header
      return "Name", "Score", "Age", "YaMls", "UUID"
    end

    def print_item
      return @name, @score.to_s, age, "[#{@yamls.join(',')}]", @current_yaml.to_s, "[#{@images.join(',')}]", "[#{@like_images.join(',')}]", @uuid
    end

    def print_item_header
      return "Name", "Score", "Age", "YaMLs", "Current-YaML", "Images", "Likes", "UUID"
    end

    def print_items
      return @name, @score.to_s, age, @yamls.size.to_s, @uuid
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
