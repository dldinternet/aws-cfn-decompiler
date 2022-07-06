require "aws/cfn/decompiler/version"
require "aws/cfn/decompiler/base"

require 'slop'

module Aws
  module Cfn
    module DeCompiler
      class Main < Base
        attr_accessor :template

        def run

          parse_options

          set_config_options

          unless @config[:directory].nil?
            unless File.directory?(@config[:directory])
              Dir.mkdir(@config[:directory])
            end
            unless File.directory?(@config[:directory])
              @logger.error "Cannot see output directory: #{@config[:directory]}"
              @logger.error @config.to_s
              exit
            end
          end

          decompiled = load_template @config[:template]

          validate(decompiled)

          output_dir = @config[:directory] || Dir.pwd
          save_dsl(output_dir,decompiled)

          @logger.step '*** Decompiled Successfully ***'
        end

        protected


      end
    end
  end
end
