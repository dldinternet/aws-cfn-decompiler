require "aws/cfn/decompiler/version"
require "aws/cfn/decompiler/base"

require 'slop'

module Aws
  module Cfn
    module DeCompiler
      class Main < Base
        attr_accessor :template

        def run

          @opts = Slop.parse(help: true, strict: true) do
            # command File.basename(__FILE__,'.rb')
            on :j, :template=,      'The template to decompile', as: String
            on :o, :output=,        'The directory to output the components to.', as: String
            on :f, :format=,        'The output format of the components. [JSON|YAML|Ruby]', as: String, match: %r/ruby|rb|yaml|yml|json|js/i
            on :s, :specification=, 'The specification file to create.', as: String
            on :n, :functions=,     'Enable function use.', as: String, match: %r/0|1|yes|no|on|off|enable|disable|set|unset|true|false|raw/i
          end

          @config[:functions] = @opts[:functions].downcase.match %r'^(1|true|on|yes|enable|set)$'

          unless @opts[:template]
            @logger.error @opts
            exit
          end
          unless @opts[:output].nil?
            unless File.directory?(@opts[:output])
              Dir.mkdir(@opts[:output])
            end
            unless File.directory?(@opts[:output])
              @logger.error "Cannot see output directory: #{@opts[:output]}"
              @logger.error @opts.to_s
              exit
            end
          end

          load @opts[:template]

          validate(@items)

          output_dir = @opts[:output] || Dir.pwd
          save(output_dir)

          @logger.step '*** Decompiled Successfully ***'
        end

        protected


      end
    end
  end
end
