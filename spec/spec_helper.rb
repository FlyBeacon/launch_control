$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'launch_control'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

LaunchControl.configure do |config|
  config.mandrill_api_key = 'test-key'
end
