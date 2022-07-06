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

        require "aws/cfn/decompiler/mixins/options"
        include Aws::Cfn::DeCompiler::Options

        def save_dsl(output_dir, decompiled=@items)

          specification = {}
          format = @config[:format] rescue 'yaml'
          ruby   = (not format.match(%r'^ruby|rb$').nil?)
          if ruby
            pprint_cfn_template simplify(decompiled)
          end
          decompiled.each do |section, section_items|
            case section
              when /Mappings|Parameters|Conditions|Resources|Outputs/
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
          unless @config[:specification].nil?
            dir = File.dirname(@config[:specification])
            dir = output_dir unless dir
            save_section(dir, File.basename(@config[:specification]), format, '', specification, '', "specification")
          end

        end

        protected

      end
    end
  end
end
