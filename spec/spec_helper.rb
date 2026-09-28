# frozen_string_literal: true

require "json"
require "webmock/rspec"
require_relative "../lib/shopsavvy_data_api"

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.disable_monkey_patching!
  config.order = :random
end

def fixture_json(name)
  File.read(File.join(__dir__, "fixtures", name))
end
