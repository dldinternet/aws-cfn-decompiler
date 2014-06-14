require "aws/cfn/decompiler/version"
require "aws/cfn/compiler"

require 'json'
require 'ap'
require 'yaml'
require 'slop'

module Aws
  module Cfn
    module DeCompiler
      class Main < Aws::Cfn::Compiler::Main
        attr_accessor :template

        def run

          @opts = Slop.parse(help: true, strict: true) do
            on :j, :template=, 'The template to decompile', as: String
            on :o, :output=, 'The directory to output the components to.', as: String
            on :f, :format=, 'The output format of the components. [JSON|YAML]', as: String, match: %r/yaml|json/i
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

          load @opts[:template]

          puts
          puts 'Validating decompiled file...'

          validate(@items)

          output_dir = @opts[:output] || Dir.pwd
          puts
          puts "Writing decompiled parts to #{output_dir}..."
          save(output_dir)

          puts
          puts '*** Decompiled Successfully ***'
        end

        def save(output_dir)

          format = @opts[:format] rescue 'yaml'
          [ :Mappings, :Parameters, :Resources, :Outputs ].each do |section|

            @items[section].each do |name,value|
              dir  = File.join(output_dir,section.to_s)
              unless File.directory?(dir)
                Dir.mkdir(dir)
              end
              file = "#{name}.#{format}"
              path = File.join(dir,file)

              hash = {  name => value }

              begin
                File.delete path if File.exists? path
                File.open path, 'w' do |f|
                  case format
                    when /json/
                      f.write JSON.pretty_generate(compiled)
                    when /yaml/
                      f.write hash.to_yaml line_width: 1024, indentation: 4, canonical: false
                    else
                      raise "Unsupported format #{format}. Should have noticed this earlier!"
                  end
                  f.close
                end
                puts "  decompiled #{section}/#{file}."
              rescue
                puts "!!! Could not write compiled file #{path}: #{$!}"
                abort!
              end
            end

          end
        end

        def load(file=nil)
          if file
            begin
              abs = File.absolute_path(File.expand_path(file))
              unless File.exists?(abs) or @opts[:output].nil?
                abs = File.absolute_path(File.expand_path(File.join(@opts[:output],file)))
              end
            rescue
              # pass
            end
            if File.exists?(abs)
              case File.extname(File.basename(abs)).downcase
                when /json/
                  template = JSON.parse(File.read(abs))
                when /yaml/
                  template = YAML.load(File.read(abs))
                else
                  raise "Unsupported file type for specification: #{file}"
              end
              #@items = template

              template.each {|key,val|
                @items[key.to_sym] = val
              }

            else
              raise "Unable to open template: #{abs}"
            end
          end
        end

        protected


      end
    end
  end
end
