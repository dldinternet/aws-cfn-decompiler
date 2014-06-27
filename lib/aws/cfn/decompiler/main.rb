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
            on :j, :template=,      'The template to decompile', as: String
            on :o, :output=,        'The directory to output the components to.', as: String
            on :f, :format=,        'The output format of the components. [JSON|YAML|Ruby]', as: String, match: %r/yaml|json|ruby/i
            on :s, :specification=, 'The specification file to create.', as: String
          end

          unless @opts[:template]
            puts @opts
            exit
          end
          unless @opts[:output].nil?
            unless File.directory?(@opts[:output])
              puts @opts
              exit
            end
          end

          decompile @opts[:template]

          output_dir = @opts[:output] || Dir.pwd
          puts
          puts "Writing decompiled parts to #{output_dir}..."
          save(output_dir)

          puts
          puts '*** Decompiled Successfully ***'
        end

        protected


      end
    end
  end
end
