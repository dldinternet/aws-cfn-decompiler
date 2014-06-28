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
          ruby   = (not format.match(%r'^ruby|rb$').nil?)
          if ruby
            pprint_cfn_template simplify(@items)
          end
          @items.each do |section, section_items|
            case section
              when /Mappings|Parameters|Resources|Outputs/
                specification[section] = []
                section_items.each do |name,value|
                  unless ruby
                    dir  = File.join(output_dir,section.to_s)
                    unless File.directory?(dir)
                      Dir.mkdir(dir)
                    end
                    file = "#{name}.#{format}"
                    hash = {  name => value }

                    save_section(dir, file, format, section, hash)
                  end
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

        protected

        def save_section(dir, file, format, section, hash, join='/')
          logStep "Saving section #{hash.keys[0]} to #{section}/#{file} "
          path = File.join(dir, file)

          begin
            if i_am_maintainer(path)
              # File.delete path if File.exists? path
              File.open path, File::CREAT|File::TRUNC|File::RDWR, 0644 do |f|
                case format
                  when /ruby|rb|yaml|yml/
                    f.write maintainer_comment('')
                    f.write hash.to_yaml line_width: 1024, indentation: 4, canonical: false
                  when /json|js/
                    # You wish ... f.write maintainer_comment('')
                    f.write JSON.pretty_generate(hash)
                  else
                    abort! "Internal: Unsupported format #{format}. Should have noticed this earlier!"
                end
                f.close
              end
              @logger.info "  decompiled #{section}#{join}#{file}."
            else
              @logger.warn "  Did not overwrite #{section}#{join}#{file}."
            end
          rescue
            abort! "!!! Could not write compiled file #{path}: #{$!}"
          end
        end

      end
    end
  end
end
