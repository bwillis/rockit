require 'bundler'
Bundler.require

require 'rockit'
require 'rspec'

#require 'active_support/string_inquirer'
Dir[File.expand_path(File.join(File.dirname(__FILE__), "support/**/*.rb"))].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :mocha
end