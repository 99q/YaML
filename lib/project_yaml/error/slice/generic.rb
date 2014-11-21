module ProjectYaML
  module Error
    class Slice

      class Generic < ProjectYaML::Error::Generic

        def initialize(message)
          super(message)
          @http_err = :forbidden
          @std_err = 1
        end

      end

    end
  end
end
