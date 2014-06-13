require "aws/cfn/decompiler/version"

require 'json'
require 'ap'
require 'yaml'
require 'slop'

module Aws
  module Cfn
    module DeCompiler
      class Main < Aws::Cfn::Compiler::Main
        def run

          @opts = Slop.parse(help: true) do
            on :d, :directory=, 'The directory to look in', as: String
            on :o, :output=, 'The JSON file to output', as: String
            on :s, :specification=, 'The specification to use when selecting components. A JSON or YAML file or JSON object', as: String
            on :f, :formatversion=, 'The AWS Template format version. Default 2010-09-09', as: String
            on :t, :description=, "The AWS Template description. Default: output basename or #{File.basename(__FILE__,'.rb')}", as: String
          end

          unless @opts[:directory]
            puts @opts
            exit
          end

          load @opts[:specification]

          desc = @opts[:output] ? File.basename(@opts[:output]).gsub(%r/\.(json|yaml)/, '') : File.basename(__FILE__,'.rb')
          if @spec and @spec['description']
            desc = @spec['description']
          end
          compiled = {
              AWSTemplateFormatVersion: (@opts[:formatversion].nil? ? '2010-09-09' : @opts[:formatversion]),
              Description:              (@opts[:description].nil? ? desc : @opts[:description]),
              Parameters:               @items['params'],
              Mappings:                 @items['mappings'],
              Resources:                @items['resources'],
              Outputs:                  @items['outputs'],
          }

          output_file = @opts[:output] || 'compiled.json'
          puts
          puts "Writing compiled file to #{output_file}..."
          save(compiled, output_file)

          puts
          puts 'Validating compiled file...'

          validate(compiled)

          puts
          puts '*** Compiled Successfully ***'
        end

        def save(compiled, output_file)
          begin
            File.open output_file, 'w' do |f|
              f.write JSON.pretty_generate(compiled)
            end
            puts '  Compiled file written.'
          rescue
            puts "!!! Could not write compiled file: #{$!}"
            abort!
          end
        end

        def load(spec=nil)
          if spec
            begin
              abs = File.absolute_path(File.expand_path(spec))
              unless File.exists?(abs)
                abs = File.absolute_path(File.expand_path(File.join(@opts[:directory],spec)))
              end
            rescue
              # pass
            end
            if File.exists?(abs)
              raise 'Unsupported specification file type' unless abs =~ /\.(json|ya?ml)\z/i

              puts "Loading specification #{abs}..."
              spec = File.read(abs)

              case File.extname(File.basename(abs)).downcase
                when /json/
                  spec = JSON.parse(spec)
                when /yaml/
                  spec = YAML.load(spec)
                else
                  raise "Unsupported file type for specification: #{spec}"
              end
              @spec = spec
            else
              raise "Unable to open specification: #{abs}"
            end
          end
          %w{params mappings resources outputs}.each do |dir|
            load_dir(dir,spec)
          end
        end

        protected


      end
    end
  end
end
