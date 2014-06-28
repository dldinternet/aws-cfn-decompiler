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
          if format.match(%r'^ruby|rb$')
            pprint_cfn_template simplify(@items)
          else
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
                  abort! "Unsupported section '#{section}' in template"
              end

            end

            # Save specification
            unless @opts[:specification].nil?
              dir = File.dirname(@opts[:specification])
              dir = output_dir unless dir
              save_section(dir, File.basename(@opts[:specification]), format, '', specification, "Specification to #{dir}/")
            end
          end

        end

        def save_section(dir, file, format, section, hash, join='/')
          logStep "Saving section #{hash.keys[0]} to #{section}/#{file} "
          path = File.join(dir, file)

          begin
            # File.delete path if File.exists? path
            File.open path, File::CREAT|File::TRUNC|File::RDWR, 0644 do |f|
              case format
                when /ruby|rb/
                  @output.unshift f
                  pprint(hash)
                  @output.shift
                when /json|js/
                  f.write JSON.pretty_generate(hash)
                when /yaml|yml/
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

        def load(file=nil)
          if file
            logStep "Loading #{file}"
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
                when /json|js/
                  @items = JSON.parse(File.read(abs))
                when /yaml|yml/
                  @items = YAML.load(File.read(abs))
                else
                  abort! "Unsupported file type for specification: #{file}"
              end
            else
              abort! "Unable to open template: #{abs}"
            end
          end
        end

        protected

      end
    end
  end
end
