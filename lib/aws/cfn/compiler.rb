require "aws/cfn/compiler/version"

require 'json'
require 'ap'
require 'yaml'
require 'slop'

module Aws
  module Cfn
    module Compiler
      class Main
        attr_accessor :items
        attr_accessor :opts

        def initialize
          @items = {}
        end

        def run ()

          @opts = Slop.parse(help: true) do
            on :d, :directory=, 'The directory to look in', as: String
            on :o, :output=, 'The JSON file to output', as: String
          end

          unless @opts[:directory]
            puts @opts
            exit
          end

          load

          compiled = {
              AWSTemplateFormatVersion: "2010-09-09",
              Description:              "Description goes here",
              Parameters:               @items['params'],
              Mappings:                 @items['mappings'],
              Resources:                @items['resources'],
              Outputs:                  @items['outputs'],
          }

          output_file = @opts[:output] || "compiled.json"
          puts
          puts "Writing compiled file to #{output_file}..."
          save(compiled, output_file)

          puts
          puts "Validating compiled file..."

          validate(compiled)

          puts
          puts "*** Compiled Successfully ***"
        end

        def validate(compiled)
          names = compiled["Resources"].keys + compiled["Parameters"].keys
          refs = find_refs(compiled).select { |a| !(a =~ /^AWS::/) }

          unless (refs-names).empty?
            puts "!!! Unknown references !!!"
            (refs-names).each do |name|
              puts "  #{name}"
            end
            abort!
          end
          puts "  References validated"
        end

        def save(compiled, output_file)
          begin
            File.open output_file, 'w' do |f|
              f.write JSON.pretty_generate(compiled)
            end
            puts "  Compiled file written."
          rescue
            puts "!!! Could not write compiled file: #{$!}"
            abort!
          end
        end

        def load
          %w{params mappings resources outputs}.each do |dir|
            load_dir(dir)
          end
        end

        protected

        def abort!
          puts "!!! Aborting !!!"
          exit
        end

        def find_refs(hash)
          if hash.is_a? Hash
            tr = []
            hash.keys.collect do |key|
              if %w{Ref SourceSecurityGroupName CacheSecurityGroupNames SecurityGroupNames}.include? key
                hash[key]
              elsif "Fn::GetAtt" == key
                hash[key].first
              else
                find_refs(hash[key])
              end
            end.flatten.compact.uniq
          elsif hash.is_a? Array
            hash.collect{|a| find_refs(a)}.flatten.compact.uniq
          end
        end

        def load_dir(dir)
          puts "Loading #{dir}..."
          @items[dir] = {}
          (Dir[File.join(@opts[:directory], "#{dir}.*")] | Dir[File.join(@opts[:directory], dir, "**", "*")]).collect do |filename|
            next unless filename =~ /\.(json|ya?ml)\z/i
            begin
              puts "  reading #{filename}"
              content = File.read(filename)
              next if content.size==0

              if filename =~ /\.json\z/i
                item = JSON.parse(content)
              elsif filename =~ /\.ya?ml\z/i
                item = YAML.load(content)
              else
                next
              end
              item.keys.each { |key| raise "Duplicate item: #{key}" if @items[dir].has_key?(key) }
              @items[dir].merge! item
            rescue
              puts "  !! error: #{$!}"
              abort!
            end
          end
        end

      end
    end
  end
end
