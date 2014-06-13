# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws/cfn/decompiler/version'

Gem::Specification.new do |spec|
  spec.name          = "aws-cfn-decompiler"
  spec.version       = Aws::Cfn::DeCompiler::VERSION
  spec.authors       = ["Christo De Lange"]
  spec.email         = ["rubygems@dldinternet.com"]
  spec.summary       = %q{A simple script to decompile and produce reusable components for CloudFormation templates.}
  spec.description   = %q{The idea is to extract a big CloudFormation template into a folder structure to better manage pieces of a CloudFormation deployment. Additionally, writing in JSON is hard, so the decompiler can create YAML files as well.}
  spec.homepage      = "https://github.com/dldinternet/aws-cfn-decompiler"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "awesome_print"
  spec.add_dependency "slop"
  spec.add_dependency "psych"
  spec.add_dependency "json"
  spec.add_dependency 'aws-cfn-compiler', '>= 0.0.7', '~> 0.0'

  spec.add_development_dependency 'bundler', "~> 1.6"
  spec.add_development_dependency 'rake'
end
