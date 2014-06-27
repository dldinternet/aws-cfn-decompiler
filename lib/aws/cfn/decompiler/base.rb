require "aws/cfn/decompiler/version"
require "aws/cfn/compiler"

require 'json'
require 'ap'
require 'yaml'

module Aws
  module Cfn
    module DeCompiler
      class Base < ::Aws::Cfn::Compiler::Base
        attr_accessor :template

        def save(output_dir)

          specification = {}
          format = @opts[:format] rescue 'yaml'
          @items.each do |section, section_items|
            case section
              when /Mappings|Parameters|Resources|Outputs/
                specification[section] = []
                section_items.each do |name,value|
                  dir  = File.join(output_dir,section.to_s)
                  unless File.directory?(dir)
                    Dir.mkdir(dir)
                  end
                  file = "#{name}.#{format}"
                  hash = {  name => value }

                  save_section(dir, file, format, section, hash)
                  specification[section] << name
                end
              when /AWSTemplateFormatVersion|Description/
                specification[section] = section_items
              else
                raise "ERROR: Unsupported section '#{section}' in template"
            end

          end

          # Save specification
          unless @opts[:specification].nil?
            dir = File.dirname(@opts[:specification])
            dir = output_dir unless dir
            save_section(dir, File.basename(@opts[:specification]), format, '', specification, "Specification to #{dir}/")
          end

        end

        def save_section(dir, file, format, section, hash, join='/')
          path = File.join(dir, file)

          begin
            # File.delete path if File.exists? path
            File.open path, File::CREAT|File::TRUNC|File::RDWR, 0644 do |f|
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
            puts "  decompiled #{section}#{join}#{file}."
          rescue
            puts "!!! Could not write compiled file #{path}: #{$!}"
            abort!
          end
        end

        def decompile(file=nil)
          load file

          puts
          puts 'Validating decompiled file...'

          validate(@items)

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
              @items = template
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
