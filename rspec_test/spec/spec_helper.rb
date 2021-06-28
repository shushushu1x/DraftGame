# spec/spec_helper.rb
require 'rspec'
require 'rack/test'


ENV['RACK_ENV'] = 'test'

require File.expand_path 'C:/ruby_lesson/rspec_test/lib/myapp.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure { |c| c.include RSpecMixin }
