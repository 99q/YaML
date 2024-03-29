require_rel "slice/"

module ProjectYaML
  module Error
    class Slice

      [
          [ 'InputError'                , 111 , {'@http_err' => :bad_request}           , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InvalidPlugin'             , 112 , {'@http_err' => :bad_request}           , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InvalidTemplate'           , 113 , {'@http_err' => :bad_request}           , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'MissingArgument'           , 114 , {'@http_err' => :bad_request}           , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InvalidCommand'            , 115 , {'@http_err' => :bad_request}           , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InvalidUUID'               , 116 , {'@http_err' => :bad_request}           , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InvalidPathItem'           , 118 , {'@http_err' => :bad_request}           , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'CommandFailed'             , 120 , {'@http_err' => :bad_request}           , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'SliceCommandParsingFailed' , 122 , {'@http_err' => :not_found}             , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'NotFound'                  , 123 , {'@http_err' => :not_found}             , 'Not found' , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InternalError'             , 131 , {'@http_err' => :internal_server_error} , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'NotImplemented'            , 141 , {'@http_err' => :forbidden}             , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'CouldNotCreate'            , 125 , {'@http_err'=> :forbidden}              , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'CouldNotUpdate'            , 126 , {'@http_err'=> :forbidden}              , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'CouldNotRemove'            , 127 , {'@http_err'=> :forbidden}              , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'MethodNotAllowed'          , 128 , {'@http_err'=> :method_not_allowed}     , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InvalidModelTemplate'      , 150 , {'@http_err'=> :bad_request}            , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'UserCancelled'             , 151 , {'@http_err'=> :bad_request}            , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'MissingModelMetadata'      , 152 , {'@http_err'=> :bad_request}            , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InvalidModelMetadata'      , 153 , {'@http_err'=> :bad_request}            , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InvalidPolicyTemplate'     , 154 , {'@http_err'=> :bad_request}            , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'InvalidModel'              , 155 , {'@http_err'=> :bad_request}            , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'MissingTags'               , 156 , {'@http_err'=> :bad_request}            , ''          , 'ProjectYaML::Error::Slice::Generic' ],
          [ 'NoCallbackFound'           , 157 , {'@http_err'=> :bad_request}            , ''          , 'ProjectYaML::Error::Slice::Generic' ],
      ].each do |err|
        ProjectYaML::Error.create_class *err
      end

    end
  end
end
