module ProjectYaML
  module Error

    class Generic < StandardError

      attr_reader :http_err
      attr_reader :log_severity
      attr_reader :std_err

      # Initializes a new Error object
      #
      # @param message [String]
      # @return [ProjectYaML::Error]
      def initialize(message)
        super(message)
        @http_err     = :forbidden
        @log_severity = :error
        @std_err      = 1

        #A.class
        #self.class.create_class('B', {'@http_err' => :processing})
      end

      # Returns the error code for HTTP
      #
      # @return [Integer]
      def http_err_code
        http_codes[@http_err]
      end

      def http_codes
        { :continue                        => 100,
          :switching_protocols             => 101,
          :processing                      => 102,

          :ok                              => 200,
          :created                         => 201,
          :accepted                        => 202,
          :no_content                      => 204,
          :reset_content                   => 205,
          :partial_content                 => 206,
          :multi_status                    => 207,
          :im_used                         => 226,

          :multiple_choices                => 300,
          :moved_permanently               => 301,
          :found                           => 302,
          :see_other                       => 303,
          :not_modified                    => 304,
          :use_proxy                       => 305,
          :temporary_redirect              => 307,

          :bad_request                     => 400,
          :payment_required                => 402,
          :forbidden                       => 403,
          :not_found                       => 404,
          :method_not_allowed              => 405,
          :not_acceptable                  => 406,
          :proxy_authentication_required   => 407,
          :request_timeout                 => 408,
          :conflict                        => 409,
          :gone                            => 410,
          :length_required                 => 411,
          :precondition_failed             => 412,
          :request_entity_too_large        => 413,
          :request_uri_too_long            => 414,
          :unsupported_media_type          => 415,
          :requested_range_not_satisfiable => 416,
          :expectation_failed              => 417,
          :unprocessable_entity            => 422,
          :locked                          => 423,
          :failed_dependency               => 424,
          :upgrade_required                => 426,

          :internal_server_error           => 500,
          :not_implemented                 => 501,
          :bad_gateway                     => 502,
          :service_unavailable             => 503,
          :gateway_timeout                 => 504,
          :http_version_not_supported      => 505,
          :insufficient_storage            => 507,
          :not_extended                    => 510 }
      end
    end
  end
end
