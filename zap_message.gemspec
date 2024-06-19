# frozen_string_literal: true
$LOAD_PATH << File.expand_path('lib', __dir__)
require 'zap_message/version'

Gem::Specification.new do |spec|
  spec.name = 'zap_message'
  spec.version = ::ZapMessage::Version.version
  spec.authors = ['Diego Dillenburg Bueno']
  spec.email = ['diegodillenburg+github@gmail.com']
  spec.summary = 'this is the summary'
  spec.description = 'oh there is the description'
  spec.homepage = 'https://github.com/diegodillenburg/zap-message'

  spec.files = Dir.glob('lib/**/*')
  spec.require_path = 'lib'

  spec.license = 'MIT'

  spec.required_ruby_version = '~> 3.1'
  spec.add_dependency 'dotenv', '~> 3.1.2'
  spec.add_dependency 'pry', '~> 0.14'
  spec.add_dependency 'pry-byebug', '~> 3.10'
  spec.add_dependency 'rspec', '~> 3.13'
end
