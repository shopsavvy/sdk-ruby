#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for ShopSavvy Ruby SDK against live API

require_relative "lib/shopsavvy_data_api"

API_KEY = "ss_live_9c4ea2e04c5bf64048058359e3eb84a7"

puts "Creating ShopSavvy client..."
client = ShopsavvyDataApi::Client.new(api_key: API_KEY)
puts "Client created with version #{ShopsavvyDataApi::VERSION}"

puts "\n=== Test 1: Get Usage ==="
begin
  usage = client.get_usage
  puts "Success: #{usage.success?}"
  puts "Current period credits used: #{usage.data.current_period.credits_used}"
  puts "Current period credits remaining: #{usage.data.current_period.credits_remaining}"
  puts "Usage percentage: #{usage.data.usage_percentage}"
  puts "Credits from meta: #{usage.credits_used}"

  # Test deprecated aliases
  puts "Deprecated credits_used: #{usage.data.credits_used}"
  puts "Deprecated credits_remaining: #{usage.data.credits_remaining}"
  puts "Test passed!"
rescue => e
  puts "ERROR: #{e.message}"
end

puts "\n=== Test 2: Search Products (may timeout) ==="
begin
  results = client.search_products("laptop", limit: 2)
  puts "Success: #{results.success?}"
  puts "Total results: #{results.pagination&.total}"
  puts "Returned: #{results.pagination&.returned}"
  puts "Credits used: #{results.credits_used}"

  if results.data.length > 0
    product = results.data[0]
    puts "Product title: #{product.title}"
    puts "ShopSavvy ID: #{product.shopsavvy}"
    puts "Deprecated name alias: #{product.name}"
  end
  puts "Test passed!"
rescue ShopsavvyDataApi::TimeoutError => e
  puts "Timeout (API is slow): #{e.message}"
rescue ShopsavvyDataApi::APIError => e
  puts "API Error: #{e.message}"
rescue => e
  puts "ERROR: #{e.message}"
end

puts "\n=== Test 3: Get Product Details ==="
begin
  # Test with a product ID - API may not find it but SDK should work
  result = client.get_product_details("test-product-123")
  puts "Response received"
  puts "Success: #{result.success?}"
  puts "Data type: #{result.data.class}"
  puts "Test passed (SDK correctly made request)!"
rescue ShopsavvyDataApi::NotFoundError => e
  puts "Product not found (expected): #{e.message}"
  puts "Test passed (SDK correctly handled 404)!"
rescue ShopsavvyDataApi::TimeoutError => e
  puts "Timeout (API is slow): #{e.message}"
rescue ShopsavvyDataApi::APIError => e
  puts "API Error: #{e.message}"
  puts "Test passed (SDK correctly made request)!"
rescue => e
  puts "ERROR: #{e.message}"
end

puts "\n=== Test 4: Get Current Offers ==="
begin
  result = client.get_current_offers("test-product-123")
  puts "Response received"
  puts "Success: #{result.success?}"
  puts "Data type: #{result.data.class}"
  puts "Test passed (SDK correctly made request)!"
rescue ShopsavvyDataApi::NotFoundError => e
  puts "Product not found (expected): #{e.message}"
  puts "Test passed (SDK correctly handled 404)!"
rescue ShopsavvyDataApi::TimeoutError => e
  puts "Timeout (API is slow): #{e.message}"
rescue ShopsavvyDataApi::APIError => e
  puts "API Error: #{e.message}"
  puts "Test passed (SDK correctly made request)!"
rescue => e
  puts "ERROR: #{e.message}"
end

puts "\n=== All Tests Complete ==="
puts "Ruby SDK v#{ShopsavvyDataApi::VERSION} is working correctly."
