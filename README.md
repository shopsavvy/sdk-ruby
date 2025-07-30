# ShopSavvy Data API - Ruby SDK

[![Gem Version](https://badge.fury.io/rb/shopsavvy_data_api.svg)](https://badge.fury.io/rb/shopsavvy_data_api)
[![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%202.7.0-red.svg)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Official Ruby SDK for the [ShopSavvy Data API](https://shopsavvy.com/data). Access product data, pricing information, and price history across thousands of retailers and millions of products.

## 🚀 Quick Start

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'shopsavvy_data_api'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install shopsavvy_data_api
```

### Get Your API Key

1. Visit [shopsavvy.com/data](https://shopsavvy.com/data)
2. Sign up for an account
3. Choose a subscription plan
4. Get your API key from the dashboard

### Basic Usage

```ruby
require 'shopsavvy_data_api'

# Initialize the client
client = ShopsavvyDataApi.new(api_key: "ss_live_your_api_key_here")

# Look up a product by barcode
product = client.get_product_details("012345678901")
puts product.data.name

# Get current prices from all retailers
offers = client.get_current_offers("012345678901")
offers.data.each do |offer|
  puts "#{offer.retailer}: $#{offer.price}"
end

# Get price history
history = client.get_price_history(
  "012345678901",
  "2024-01-01", 
  "2024-01-31"
)
```

## 📖 API Reference

### Client Configuration

```ruby
# Method 1: Simple initialization
client = ShopsavvyDataApi.new(
  api_key: "ss_live_your_api_key_here",
  timeout: 30,  # optional
  base_url: "https://api.shopsavvy.com/v1"  # optional
)

# Method 2: Using configuration object
config = ShopsavvyDataApi::Configuration.new(
  api_key: "ss_live_your_api_key_here",
  timeout: 60
)
client = ShopsavvyDataApi.with_config(config)

# Method 3: Direct client instantiation
client = ShopsavvyDataApi::Client.new(api_key: "ss_live_your_api_key_here")
```

### Product Lookup

#### Single Product
```ruby
# Look up by barcode, ASIN, URL, or model number
product = client.get_product_details("012345678901")
amazon_product = client.get_product_details("B08N5WRWNW")  
url_product = client.get_product_details("https://www.amazon.com/dp/B08N5WRWNW")

puts "Product: #{product.data.name}"
puts "Brand: #{product.data.brand}"
puts "Category: #{product.data.category}"
```

#### Multiple Products
```ruby
products = client.get_product_details_batch([
  "012345678901",
  "B08N5WRWNW",
  "https://www.bestbuy.com/site/product/123456"
])

products.data.each do |product|
  puts "#{product.name} by #{product.brand}"
end
```

### Current Pricing

#### All Retailers
```ruby
offers = client.get_current_offers("012345678901")
puts "Found #{offers.data.length} offers"

# Sort by price
sorted_offers = offers.data.sort_by(&:price)
cheapest = sorted_offers.first
puts "Best price: #{cheapest.retailer} - $#{cheapest.price}"
```

#### Specific Retailer
```ruby
amazon_offers = client.get_current_offers("012345678901", retailer: "amazon")
target_offers = client.get_current_offers("012345678901", retailer: "target")
```

#### Multiple Products
```ruby
batch_offers = client.get_current_offers_batch([
  "012345678901",
  "B08N5WRWNW"
])

batch_offers.data.each do |identifier, offers|
  puts "#{identifier}: #{offers.length} offers"
end
```

### Price History

```ruby
# Get 30 days of price history
history = client.get_price_history(
  "012345678901",
  "2024-01-01",
  "2024-01-31"
)

history.data.each do |offer|
  puts "#{offer.retailer}:"
  puts "  Current price: $#{offer.price}"
  puts "  Historical data points: #{offer.price_history.length}"
  puts "  Average price: $#{offer.average_price.round(2)}" if offer.average_price
  puts "  Price range: $#{offer.min_price} - $#{offer.max_price}"
end

# Get retailer-specific price history
amazon_history = client.get_price_history(
  "012345678901",
  "2024-01-01",
  "2024-01-31",
  retailer: "amazon"
)
```

### Product Monitoring

#### Schedule Monitoring
```ruby
# Monitor daily across all retailers
result = client.schedule_product_monitoring("012345678901", "daily")
puts "Scheduled: #{result.data['scheduled']}"

# Monitor hourly at Amazon only
client.schedule_product_monitoring(
  "012345678901", 
  "hourly", 
  retailer: "amazon"
)

# Schedule multiple products
batch_result = client.schedule_product_monitoring_batch([
  "012345678901",
  "B08N5WRWNW"
], "daily")
```

#### Manage Scheduled Products
```ruby
# Get all scheduled products
scheduled = client.get_scheduled_products
puts "Monitoring #{scheduled.data.length} products"

scheduled.data.each do |product|
  retailer_info = product.retailer || "all retailers"
  puts "#{product.identifier}: #{product.frequency} at #{retailer_info}"
  puts "  Created: #{product.created_at}"
  puts "  Last refreshed: #{product.last_refreshed}" if product.last_refreshed
end

# Remove from schedule
client.remove_product_from_schedule("012345678901")

# Remove multiple products
client.remove_products_from_schedule(["012345678901", "B08N5WRWNW"])
```

### Usage Tracking

```ruby
usage = client.get_usage
puts "Credits remaining: #{usage.data.credits_remaining}"
puts "Credits used: #{usage.data.credits_used}"
puts "Plan: #{usage.data.plan_name}"
puts "Usage: #{usage.data.credits_percentage_used}%"
puts "Billing period: #{usage.data.billing_period_start} to #{usage.data.billing_period_end}"
```

## 🔧 Advanced Usage

### Error Handling

```ruby
begin
  product = client.get_product_details("invalid-identifier")
rescue ShopsavvyDataApi::NotFoundError => e
  puts "Product not found"
rescue ShopsavvyDataApi::AuthenticationError => e
  puts "Invalid API key"
rescue ShopsavvyDataApi::RateLimitError => e
  puts "Rate limit exceeded - slow down requests"
rescue ShopsavvyDataApi::ValidationError => e
  puts "Invalid request parameters: #{e.message}"
rescue ShopsavvyDataApi::TimeoutError => e
  puts "Request timed out"
rescue ShopsavvyDataApi::NetworkError => e
  puts "Network error: #{e.message}"
rescue ShopsavvyDataApi::APIError => e
  puts "API error: #{e.message}"
  puts "Status code: #{e.status_code}" if e.status_code
end
```

### Response Format

All API methods return a consistent response format:

```ruby
response = client.get_product_details("012345678901")

puts "Success: #{response.success?}"
puts "Data: #{response.data}"
puts "Credits used: #{response.credits_used}"
puts "Credits remaining: #{response.credits_remaining}"

# Access the actual data
product = response.data
puts "Product name: #{product.name}"
```

### Model Convenience Methods

```ruby
# Offer convenience methods
offer = offers.data.first
puts "In stock: #{offer.in_stock?}"
puts "New condition: #{offer.new_condition?}"

# Scheduled product convenience methods
scheduled_product = scheduled.data.first
puts "Daily monitoring: #{scheduled_product.daily?}"

# Usage info convenience methods
usage_info = usage.data
puts "#{usage_info.credits_percentage_remaining}% credits remaining"
```

### CSV Format

Some endpoints support CSV format for easier data processing:

```ruby
# Get product details in CSV format
product_csv = client.get_product_details("012345678901", format: "csv")

# Get offers in CSV format
offers_csv = client.get_current_offers("012345678901", format: "csv")

# Process with CSV library
require 'csv'

CSV.parse(offers_csv.data, headers: true) do |row|
  puts "#{row['retailer']}: $#{row['price']}"
end
```

### Working with Hashes

All model objects can be converted to hashes:

```ruby
product = client.get_product_details("012345678901")

# Convert to hash
product_hash = product.data.to_h
puts product_hash[:name]

# Convert entire response to hash
response_hash = product.to_h
puts response_hash[:data][:name]
```

## 💡 Examples

### Price Comparison Tool
```ruby
def compare_prices(client, identifier)
  offers = client.get_current_offers(identifier)
  
  if offers.data.empty?
    puts "No offers found"
    return
  end
  
  sorted_offers = offers.data.sort_by(&:price)
  cheapest = sorted_offers.first
  most_expensive = sorted_offers.last
  
  puts "🏆 Best price: #{cheapest.retailer} - $#{cheapest.price}"
  puts "💸 Highest price: #{most_expensive.retailer} - $#{most_expensive.price}"
  puts "💰 Potential savings: $#{most_expensive.price - cheapest.price}"
  
  {
    best_offer: cheapest,
    worst_offer: most_expensive,
    savings: most_expensive.price - cheapest.price
  }
end

# Usage
client = ShopsavvyDataApi.new(api_key: "your_api_key")
comparison = compare_prices(client, "012345678901")
```

### Price Alert System
```ruby
def setup_price_alert(client, identifier, target_price)
  # Schedule daily monitoring
  client.schedule_product_monitoring(identifier, "daily")
  
  # Check current prices
  offers = client.get_current_offers(identifier)
  best_offer = offers.data.min_by(&:price)
  
  if best_offer.price <= target_price
    puts "🎉 Target price reached!"
    puts "💸 #{best_offer.retailer}: $#{best_offer.price}"
    puts "🔗 Buy now: #{best_offer.url}"
    true
  else
    puts "⏰ Monitoring #{identifier}"
    puts "💰 Current best: $#{best_offer.price} (target: $#{target_price})"
    puts "📈 Need $#{(best_offer.price - target_price).round(2)} price drop"
    false
  end
end

# Usage
client = ShopsavvyDataApi.new(api_key: "your_api_key")
setup_price_alert(client, "012345678901", 299.99)
```

### Historical Price Analysis
```ruby
require 'date'

def analyze_price_trends(client, identifier, days = 30)
  end_date = Date.today
  start_date = end_date - days
  
  history = client.get_price_history(
    identifier,
    start_date.strftime("%Y-%m-%d"),
    end_date.strftime("%Y-%m-%d")
  )
  
  analysis = {}
  
  history.data.each do |offer|
    next if offer.price_history.empty?
    
    prices = offer.price_history.map(&:price)
    
    # Calculate trend
    recent_prices = prices.last(7)  # Last week
    older_prices = prices.first(prices.length - 7)  # Everything else
    
    trend = if recent_prices.length > 0 && older_prices.length > 0
              recent_avg = recent_prices.sum.to_f / recent_prices.length
              older_avg = older_prices.sum.to_f / older_prices.length
              recent_avg > older_avg ? "📈 Rising" : "📉 Falling"
            else
              "📊 Insufficient data"
            end
    
    analysis[offer.retailer] = {
      current_price: offer.price,
      average_price: offer.average_price,
      min_price: offer.min_price,
      max_price: offer.max_price,
      data_points: offer.price_history.length,
      trend: trend
    }
  end
  
  analysis
end

# Usage
client = ShopsavvyDataApi.new(api_key: "your_api_key")
trends = analyze_price_trends(client, "012345678901", 60)

trends.each do |retailer, data|
  puts "#{retailer}:"
  puts "  Current: $#{data[:current_price]}"
  puts "  Average: $#{data[:average_price].round(2)}"
  puts "  Range: $#{data[:min_price]} - $#{data[:max_price]}"
  puts "  Trend: #{data[:trend]}"
  puts
end
```

### Bulk Product Monitoring
```ruby
def setup_bulk_monitoring(client, identifiers, frequency = "daily")
  # Schedule all products
  result = client.schedule_product_monitoring_batch(identifiers, frequency)
  
  successful = []
  failed = []
  
  result.data.each do |item|
    if item["scheduled"]
      successful << item["identifier"]
    else
      failed << item["identifier"]
    end
  end
  
  puts "✅ Successfully scheduled: #{successful.length} products"
  puts "❌ Failed to schedule: #{failed.length} products"
  
  if failed.any?
    puts "Failed products:"
    failed.each { |identifier| puts "  - #{identifier}" }
  end
  
  { successful: successful, failed: failed }
end

# Usage
client = ShopsavvyDataApi.new(api_key: "your_api_key")
products_to_monitor = [
  "012345678901",
  "B08N5WRWNW", 
  "045496596439"
]
setup_bulk_monitoring(client, products_to_monitor, "daily")
```

### Rails Integration Example
```ruby
# app/models/price_tracker.rb
class PriceTracker < ApplicationRecord
  validates :product_identifier, presence: true
  validates :target_price, presence: true, numericality: { greater_than: 0 }
  
  def self.check_all_alerts
    client = ShopsavvyDataApi.new(api_key: Rails.application.credentials.shopsavvy_api_key)
    
    PriceTracker.active.find_each do |tracker|
      tracker.check_price_alert(client)
    end
  end
  
  def check_price_alert(client)
    offers = client.get_current_offers(product_identifier)
    best_offer = offers.data.min_by(&:price)
    
    if best_offer && best_offer.price <= target_price
      # Send notification
      PriceAlertMailer.target_price_reached(self, best_offer).deliver_later
      update!(alert_triggered: true, triggered_at: Time.current)
    end
  rescue ShopsavvyDataApi::Error => e
    Rails.logger.error "ShopSavvy API error for tracker #{id}: #{e.message}"
  end
end

# Usage in rake task or background job
# bin/rails runner "PriceTracker.check_all_alerts"
```

## 🛠️ Development

### Installing for Development

```bash
git clone https://github.com/shopsavvy/ruby-sdk
cd ruby-sdk
bundle install
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with coverage
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/client_spec.rb

# Run with verbose output
bundle exec rspec --format documentation --color
```

### Code Quality

```bash
# Linting
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -A

# Type checking (if using Sorbet)
bundle exec srb tc

# Generate documentation
bundle exec yard doc
```

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

## 📚 Additional Resources

- [ShopSavvy Data API Documentation](https://shopsavvy.com/data/documentation)
- [API Dashboard](https://shopsavvy.com/data/dashboard)
- [Support](mailto:business@shopsavvy.com)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏢 About ShopSavvy

ShopSavvy is a price comparison and shopping app that helps users find the best deals on products across various retailers. Since 2008, ShopSavvy has been downloaded over 40 million times and helps millions of users save money every day.

Our Data API provides the same powerful product data and pricing intelligence that powers our consumer app, available to developers and businesses worldwide.

---

**Need help?** Contact us at [business@shopsavvy.com](mailto:business@shopsavvy.com) or visit [shopsavvy.com/data](https://shopsavvy.com/data) for more information.