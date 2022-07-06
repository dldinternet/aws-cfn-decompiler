module Aws
  module Cfn
    module DeCompiler
      module Options

        def parse_options
          # noinspection RubySuperCallWithoutSuperclassInspection
          setup_options

          @opts.on :F, :format=,        'The output format of the components. [JSON|YAML|Ruby]', { as: String, match: @format_regex, default: 'yaml' }
          @opts.on :s, :specification=, 'The specification file to create.', as: String

          @opts.parse!

          unless @opts[:directory]
            puts @opts
            abort! "Missing required option --directory"
          end

          unless @opts[:template]
            puts @opts
            abort! "Missing required option --template"
          end

        end

        def set_config_options
          setup_config
        end

      end
    end
  end
end

