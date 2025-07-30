# ShopSavvy Data API - Ruby SDK

[![Gem Version](https://badge.fury.io/rb/shopsavvy-sdk.svg)](https://badge.fury.io/rb/shopsavvy-sdk)
[![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%202.6.0-red.svg)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-shopsavvy.com-blue)](https://shopsavvy.com/data/documentation)

Official Ruby SDK for the [ShopSavvy Data API](https://shopsavvy.com/data). Access comprehensive product data, real-time pricing, and historical price trends across **thousands of retailers** and **millions of products**.

## ⚡ 30-Second Quick Start

```ruby
# Install
gem install shopsavvy-sdk

# Use
require 'shopsavvy_data_api'
client = ShopsavvyDataApi.new(api_key: 'ss_live_your_api_key_here')
product = client.get_product_details('012345678901')
puts "#{product.data.name} - Best price: $#{client.get_current_offers('012345678901').data.min_by(&:price).price}"
```

## 📊 Feature Comparison

| Feature | Free Tier | Pro | Enterprise |
|---------|-----------|-----|-----------|
| **API Calls/Month** | 1,000 | 100,000 | Unlimited |
| **Product Details** | ✅ | ✅ | ✅ |
| **Real-time Pricing** | ✅ | ✅ | ✅ |
| **Price History** | 30 days | 1 year | 5+ years |
| **Bulk Operations** | 10/batch | 100/batch | 1000/batch |
| **Retailer Coverage** | 50+ | 500+ | 1000+ |
| **Rate Limiting** | 60/hour | 1000/hour | Custom |
| **Support** | Community | Email | Phone + Dedicated |

## 🚀 Installation & Setup

### Installation

Add to your Gemfile:
```ruby
gem 'shopsavvy-sdk'
```

Or install directly:
```bash
gem install shopsavvy-sdk
```

### Get Your API Key

1. **Sign up**: Visit [shopsavvy.com/data](https://shopsavvy.com/data)
2. **Choose plan**: Select based on your usage needs
3. **Get API key**: Copy from your dashboard
4. **Test**: Run the 30-second example above

### Environment Setup

```ruby
# For production, use environment variables
ENV['SHOPSAVVY_API_KEY'] = 'ss_live_your_api_key_here'

# Initialize client
client = ShopsavvyDataApi.new(api_key: ENV['SHOPSAVVY_API_KEY'])
```

## 📖 Complete API Reference

### Client Configuration

```ruby
# Basic configuration
client = ShopsavvyDataApi.new(
  api_key: 'ss_live_your_api_key_here',
  timeout: 30,  # Request timeout in seconds
  base_url: 'https://api.shopsavvy.com/v1'  # Custom base URL
)

# Advanced configuration with retry logic
client = ShopsavvyDataApi.new(
  api_key: 'ss_live_your_api_key_here',
  timeout: 60,
  retry_attempts: 3,
  retry_delay: 1.0,
  user_agent: 'MyApp/1.0.0'
)

# Configuration object approach
config = ShopsavvyDataApi::Configuration.new(
  api_key: 'ss_live_your_api_key_here',
  timeout: 120,
  debug: true  # Enable debug logging
)
client = ShopsavvyDataApi.with_config(config)
```

### Product Lookup

#### Single Product
```ruby
# Look up by barcode, ASIN, URL, model number, or ShopSavvy ID
product = client.get_product_details("012345678901")
amazon_product = client.get_product_details("B08N5WRWNW")  
url_product = client.get_product_details("https://www.amazon.com/dp/B08N5WRWNW")
model_product = client.get_product_details("MQ023LL/A")  # iPhone model number

puts "Product: #{product.data.name}"
puts "Brand: #{product.data.brand}"
puts "Category: #{product.data.category}"
puts "ASIN: #{product.data.asin}" if product.data.asin
puts "Model: #{product.data.model}" if product.data.model
puts "Description: #{product.data.description}" if product.data.description
```

#### Bulk Product Lookup
```ruby
# Process up to 100 products at once (Pro plan)
identifiers = [
  "012345678901", "B08N5WRWNW", "045496590048",
  "https://www.bestbuy.com/site/product/123456",
  "MQ023LL/A", "SM-S911U"  # iPhone and Samsung model numbers
]

products = client.get_product_details_batch(identifiers)

products.data.each do |product|
  puts "#{product.name} by #{product.brand} - #{product.category}"
  puts "  Identifiers: #{product.identifiers}" if product.identifiers
end

# Handle potential errors in batch processing
products.data.each_with_index do |product, index|
  if product.nil?
    puts "Failed to find product: #{identifiers[index]}"
  else
    puts "✓ Found: #{product.name}"
  end
end
```

### Real-Time Pricing

#### All Retailers Analysis
```ruby
offers = client.get_current_offers("012345678901")
puts "Found #{offers.data.length} offers across retailers"

# Advanced price analysis
sorted_offers = offers.data.sort_by(&:price)
cheapest = sorted_offers.first
most_expensive = sorted_offers.last

puts "💰 Best price: #{cheapest.retailer} - $#{cheapest.price}"
puts "💸 Highest price: #{most_expensive.retailer} - $#{most_expensive.price}"
puts "📊 Average price: $#{offers.data.map(&:price).sum / offers.data.length}"
puts "💡 Potential savings: $#{most_expensive.price - cheapest.price}"

# Filter by availability and condition
in_stock_offers = offers.data.select { |offer| offer.availability == 'in_stock' }
new_condition_offers = offers.data.select { |offer| offer.condition == 'new' }

puts "✅ In-stock offers: #{in_stock_offers.length}"
puts "🆕 New condition: #{new_condition_offers.length}"
```

#### Retailer-Specific Queries
```ruby
# Major retailers
amazon_offers = client.get_current_offers("012345678901", retailer: "amazon")
walmart_offers = client.get_current_offers("012345678901", retailer: "walmart")
target_offers = client.get_current_offers("012345678901", retailer: "target")
bestbuy_offers = client.get_current_offers("012345678901", retailer: "bestbuy")

# Compare specific retailers
retailers = %w[amazon walmart target bestbuy]
retailer_prices = {}

retailers.each do |retailer|
  offers = client.get_current_offers("012345678901", retailer: retailer)
  if offers.data.any?
    best_offer = offers.data.min_by(&:price)
    retailer_prices[retailer] = best_offer.price
  end
end

puts "Retailer price comparison:"
retailer_prices.sort_by { |_, price| price }.each do |retailer, price|
  puts "  #{retailer.capitalize}: $#{price}"
end
```

#### Bulk Price Monitoring
```ruby
# Monitor multiple products simultaneously
product_list = [
  "012345678901", "B08N5WRWNW", "045496590048",
  "B07XJ8C8F5", "B09G9FPHY6"
]

batch_offers = client.get_current_offers_batch(product_list)

batch_offers.data.each do |identifier, offers|
  next if offers.empty?
  
  best_offer = offers.min_by(&:price)
  puts "#{identifier}:"
  puts "  Best price: #{best_offer.retailer} - $#{best_offer.price}"
  puts "  Total offers: #{offers.length}"
  puts "  In stock: #{offers.count { |o| o.availability == 'in_stock' }}"
  puts
end
```

### Historical Price Analysis

#### Comprehensive Price Trends
```ruby
require 'date'

# Get 90 days of price history for detailed analysis
end_date = Date.today
start_date = end_date - 90

history = client.get_price_history(
  "012345678901",
  start_date.strftime("%Y-%m-%d"),
  end_date.strftime("%Y-%m-%d")
)

puts "📈 90-Day Price Analysis"
puts "=" * 50

history.data.each do |offer|
  next if offer.price_history.empty?
  
  prices = offer.price_history.map(&:price)
  current_price = offer.price
  
  # Statistical analysis
  avg_price = prices.sum.to_f / prices.length
  min_price = prices.min
  max_price = prices.max
  
  # Price trend calculation
  recent_prices = prices.last(7)  # Last week
  older_prices = prices.first([prices.length - 7, 1].max)
  
  trend = if recent_prices.any? && older_prices.any?
            recent_avg = recent_prices.sum.to_f / recent_prices.length
            older_avg = older_prices.sum.to_f / older_prices.length
            change_pct = ((recent_avg - older_avg) / older_avg * 100).round(1)
            
            if change_pct > 5
              "📈 Rising (+#{change_pct}%)"
            elsif change_pct < -5
              "📉 Falling (#{change_pct}%)"
            else
              "📊 Stable (#{change_pct}%)"
            end
          else
            "📊 Insufficient data"
          end
  
  puts "🏪 #{offer.retailer.upcase}"
  puts "  Current: $#{current_price}"
  puts "  Average: $#{avg_price.round(2)}"
  puts "  Range: $#{min_price} - $#{max_price}"
  puts "  Savings opportunity: $#{(current_price - min_price).round(2)}"
  puts "  Trend: #{trend}"
  puts "  Data points: #{offer.price_history.length}"
  puts
end
```

#### Retailer-Specific Historical Analysis
```ruby
# Compare price history across major retailers
retailers = %w[amazon walmart target bestbuy]
historical_comparison = {}

retailers.each do |retailer|
  history = client.get_price_history(
    "012345678901",
    "2024-01-01",
    "2024-12-31",
    retailer: retailer
  )
  
  next if history.data.empty?
  
  offer = history.data.first
  if offer.price_history.any?
    prices = offer.price_history.map(&:price)
    historical_comparison[retailer] = {
      current: offer.price,
      average: prices.sum.to_f / prices.length,
      lowest: prices.min,
      highest: prices.max,
      volatility: prices.max - prices.min
    }
  end
end

puts "Retailer Historical Comparison:"
historical_comparison.each do |retailer, data|
  puts "#{retailer.capitalize}:"
  puts "  Current: $#{data[:current]}"
  puts "  Average: $#{data[:average].round(2)}"
  puts "  Best ever: $#{data[:lowest]}"
  puts "  Worst: $#{data[:highest]}"
  puts "  Volatility: $#{data[:volatility].round(2)}"
  puts
end
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

## 🚀 Production Deployment

### Ruby on Rails Integration

```ruby
# Gemfile
gem 'shopsavvy-sdk'
gem 'sidekiq'  # For background jobs

# config/application.rb
config.shopsavvy_api_key = Rails.application.credentials.shopsavvy_api_key

# app/services/price_tracking_service.rb
class PriceTrackingService
  def initialize
    @client = ShopsavvyDataApi.new(
      api_key: Rails.application.config.shopsavvy_api_key,
      timeout: 60
    )
  end

  def track_product(product_id, target_price)
    # Schedule monitoring
    @client.schedule_product_monitoring(product_id, 'daily')
    
    # Create local tracking record
    PriceAlert.create!(
      product_identifier: product_id,
      target_price: target_price,
      status: 'active'
    )
  end

  def check_price_alerts
    PriceAlert.active.find_each do |alert|
      CheckPriceAlertJob.perform_later(alert.id)
    end
  end
end

# app/jobs/check_price_alert_job.rb
class CheckPriceAlertJob < ApplicationJob
  queue_as :default
  
  def perform(alert_id)
    alert = PriceAlert.find(alert_id)
    client = ShopsavvyDataApi.new(api_key: Rails.application.config.shopsavvy_api_key)
    
    offers = client.get_current_offers(alert.product_identifier)
    best_offer = offers.data.min_by(&:price)
    
    if best_offer && best_offer.price <= alert.target_price
      # Send notification
      PriceAlertMailer.target_reached(alert, best_offer).deliver_now
      alert.update!(status: 'triggered', triggered_at: Time.current)
    end
  rescue ShopsavvyDataApi::Error => e
    Rails.logger.error "ShopSavvy API error: #{e.message}"
    # Optionally retry or alert administrators
  end
end
```

### Sinatra Microservice

```ruby
# app.rb
require 'sinatra'
require 'json'
require 'shopsavvy_data_api'

class PriceAPI < Sinatra::Base
  configure do
    set :shopsavvy_client, ShopsavvyDataApi.new(
      api_key: ENV['SHOPSAVVY_API_KEY'],
      timeout: 30
    )
  end

  before do
    content_type :json
  end

  get '/api/product/:identifier/price' do
    identifier = params[:identifier]
    
    begin
      offers = settings.shopsavvy_client.get_current_offers(identifier)
      
      {
        success: true,
        product_id: identifier,
        offers: offers.data.map do |offer|
          {
            retailer: offer.retailer,
            price: offer.price,
            availability: offer.availability,
            condition: offer.condition,
            url: offer.url
          }
        end,
        best_price: offers.data.min_by(&:price)&.price,
        credits_remaining: offers.credits_remaining
      }.to_json
    rescue ShopsavvyDataApi::Error => e
      status 400
      { success: false, error: e.message }.to_json
    end
  end

  get '/api/product/:identifier/history' do
    identifier = params[:identifier]
    days = (params[:days] || 30).to_i
    
    end_date = Date.today
    start_date = end_date - days
    
    begin
      history = settings.shopsavvy_client.get_price_history(
        identifier,
        start_date.strftime('%Y-%m-%d'),
        end_date.strftime('%Y-%m-%d')
      )
      
      {
        success: true,
        product_id: identifier,
        period: "#{days} days",
        data: history.data
      }.to_json
    rescue ShopsavvyDataApi::Error => e
      status 400
      { success: false, error: e.message }.to_json
    end
  end
end
```

### Background Processing with Sidekiq

```ruby
# lib/price_monitor.rb
class PriceMonitor
  include Sidekiq::Worker
  sidekiq_options retry: 3, backtrace: true

  def perform(product_ids)
    client = ShopsavvyDataApi.new(api_key: ENV['SHOPSAVVY_API_KEY'])
    
    product_ids.each do |product_id|
      begin
        # Get current prices
        offers = client.get_current_offers(product_id)
        next if offers.data.empty?

        # Store in database or cache
        best_price = offers.data.min_by(&:price).price
        Redis.current.setex("price:#{product_id}", 3600, best_price)
        
        # Check for alerts
        check_price_alerts(product_id, best_price)
        
      rescue ShopsavvyDataApi::RateLimitError => e
        # Exponential backoff
        self.class.perform_in(2 ** sidekiq_options['retry_count'], [product_id])
        raise e
      rescue ShopsavvyDataApi::Error => e
        logger.error "API error for #{product_id}: #{e.message}"
      end
    end
  end

  private

  def check_price_alerts(product_id, current_price)
    # Implementation for checking and triggering alerts
  end
end

# Schedule regular monitoring
PriceMonitor.perform_async(['012345678901', 'B08N5WRWNW'])
```

## 💡 Real-World Use Cases

### E-commerce Price Intelligence
```ruby
# Comprehensive competitive analysis tool
class CompetitiveAnalyzer
  def initialize(api_key)
    @client = ShopsavvyDataApi.new(api_key: api_key)
  end

  def analyze_market(product_ids, competitors = %w[amazon walmart target bestbuy])
    analysis = {}
    
    product_ids.each do |product_id|
      product_analysis = analyze_product_competition(product_id, competitors)
      analysis[product_id] = product_analysis
    end
    
    generate_competitive_report(analysis)
  end

  private

  def analyze_product_competition(product_id, competitors)
    # Get product details
    product = @client.get_product_details(product_id)
    
    # Get current offers from all retailers
    all_offers = @client.get_current_offers(product_id)
    
    # Filter by target competitors
    competitor_offers = all_offers.data.select do |offer|
      competitors.include?(offer.retailer.downcase)
    end
    
    # Price analysis
    prices = competitor_offers.map(&:price)
    
    {
      product_name: product.data.name,
      brand: product.data.brand,
      total_offers: all_offers.data.length,
      competitor_offers: competitor_offers.length,
      price_range: {
        min: prices.min,
        max: prices.max,
        average: prices.sum.to_f / prices.length
      },
      market_position: calculate_market_position(competitor_offers),
      availability_score: calculate_availability_score(competitor_offers)
    }
  end

  def calculate_market_position(offers)
    return 'No data' if offers.empty?
    
    prices = offers.map(&:price).sort
    median_price = prices[prices.length / 2]
    
    case median_price
    when 0..50 then 'Budget'
    when 50..200 then 'Mid-range'
    when 200..500 then 'Premium'
    else 'Luxury'
    end
  end

  def calculate_availability_score(offers)
    return 0 if offers.empty?
    
    in_stock_count = offers.count { |offer| offer.availability == 'in_stock' }
    (in_stock_count.to_f / offers.length * 100).round(1)
  end
end

# Usage
analyzer = CompetitiveAnalyzer.new(ENV['SHOPSAVVY_API_KEY'])
report = analyzer.analyze_market([
  '012345678901', 'B08N5WRWNW', '045496590048'
])
```

### Inventory Management Integration
```ruby
# Integration with inventory management system
class InventoryPriceManager
  def initialize(api_key)
    @client = ShopsavvyDataApi.new(api_key: api_key)
  end

  def update_competitive_pricing(inventory_items)
    pricing_updates = []
    
    inventory_items.each do |item|
      next unless item.competitor_tracking_enabled?
      
      begin
        # Get current market prices
        offers = @client.get_current_offers(item.barcode)
        next if offers.data.empty?
        
        # Calculate competitive price point
        competitor_prices = offers.data.map(&:price)
        market_analysis = analyze_market_prices(competitor_prices)
        
        suggested_price = calculate_competitive_price(
          item.cost_price,
          market_analysis,
          item.target_margin
        )
        
        pricing_updates << {
          item_id: item.id,
          current_price: item.selling_price,
          suggested_price: suggested_price,
          market_analysis: market_analysis,
          reasoning: generate_pricing_reasoning(item, market_analysis, suggested_price)
        }
        
      rescue ShopsavvyDataApi::Error => e
        Rails.logger.error "Pricing update failed for #{item.id}: #{e.message}"
        next
      end
    end
    
    pricing_updates
  end

  private

  def analyze_market_prices(prices)
    sorted_prices = prices.sort
    {
      min: sorted_prices.first,
      max: sorted_prices.last,
      median: sorted_prices[sorted_prices.length / 2],
      average: prices.sum.to_f / prices.length,
      percentile_25: sorted_prices[(sorted_prices.length * 0.25).round],
      percentile_75: sorted_prices[(sorted_prices.length * 0.75).round]
    }
  end

  def calculate_competitive_price(cost_price, market_analysis, target_margin)
    min_price = cost_price * (1 + target_margin)
    competitive_price = market_analysis[:percentile_25] * 0.95  # 5% under 25th percentile
    
    [min_price, competitive_price].max.round(2)
  end
end
```

### Market Research Analytics
```ruby
# Advanced market research and trend analysis
class MarketResearcher
  def initialize(api_key)
    @client = ShopsavvyDataApi.new(api_key: api_key)
  end

  def research_category_trends(product_categories, time_periods)
    research_report = {}
    
    product_categories.each do |category, product_list|
      category_data = analyze_category_trends(product_list, time_periods)
      research_report[category] = category_data
    end
    
    generate_market_intelligence_report(research_report)
  end

  def track_seasonal_patterns(product_id, months = 12)
    patterns = {}
    
    (0...months).each do |month_offset|
      end_date = Date.today - (month_offset * 30)
      start_date = end_date - 30
      
      history = @client.get_price_history(
        product_id,
        start_date.strftime('%Y-%m-%d'),
        end_date.strftime('%Y-%m-%d')
      )
      
      month_name = end_date.strftime('%B %Y')
      patterns[month_name] = analyze_monthly_patterns(history.data)
    end
    
    identify_seasonal_trends(patterns)
  end

  private

  def analyze_monthly_patterns(history_data)
    return { average_price: 0, volatility: 0 } if history_data.empty?
    
    all_prices = []
    
    history_data.each do |offer|
      next if offer.price_history.empty?
      all_prices.concat(offer.price_history.map(&:price))
    end
    
    return { average_price: 0, volatility: 0 } if all_prices.empty?
    
    average = all_prices.sum.to_f / all_prices.length
    variance = all_prices.map { |price| (price - average) ** 2 }.sum / all_prices.length
    
    {
      average_price: average.round(2),
      volatility: Math.sqrt(variance).round(2),
      price_points: all_prices.length
    }
  end
end
```

## 🛠️ Development & Testing

### Local Development Setup

```ruby
# Clone the repository
git clone https://github.com/shopsavvy/sdk-ruby.git
cd sdk-ruby

# Install dependencies
bundle install

# Set up environment variables
echo 'SHOPSAVVY_API_KEY=ss_test_your_test_key_here' > .env

# Run tests
bundle exec rspec

# Run linting
bundle exec rubocop

# Generate documentation
bundle exec yard doc
```

### Testing Your Integration

```ruby
# Create a test script
require 'shopsavvy_data_api'

# Use test API key (starts with ss_test_)
client = ShopsavvyDataApi.new(api_key: 'ss_test_your_test_key_here')

# Test basic functionality
begin
  # Test product lookup
  product = client.get_product_details('012345678901')
  puts "✅ Product lookup: #{product.data.name}"
  
  # Test current offers
  offers = client.get_current_offers('012345678901')
  puts "✅ Current offers: #{offers.data.length} found"
  
  # Test usage info
  usage = client.get_usage
  puts "✅ API usage: #{usage.data.credits_remaining} credits remaining"
  
  puts "\n🎉 All tests passed! SDK is working correctly."
  
rescue ShopsavvyDataApi::Error => e
  puts "❌ Test failed: #{e.message}"
end
```

## 📚 Additional Resources

- **[ShopSavvy Data API Documentation](https://shopsavvy.com/data/documentation)** - Complete API reference
- **[API Dashboard](https://shopsavvy.com/data/dashboard)** - Manage your API keys and usage
- **[GitHub Repository](https://github.com/shopsavvy/sdk-ruby)** - Source code and issues
- **[RubyGems Page](https://rubygems.org/gems/shopsavvy-sdk)** - Gem releases and stats
- **[Support](mailto:business@shopsavvy.com)** - Get help from our team

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Reporting bugs
- Suggesting enhancements  
- Submitting pull requests
- Development workflow
- Code standards

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏢 About ShopSavvy

**ShopSavvy** is the world's first mobile shopping app, helping consumers find the best deals since 2008. With over **40 million downloads** and millions of active users, ShopSavvy has saved consumers billions of dollars.

### Our Data API Powers:
- 🛒 **E-commerce platforms** with competitive intelligence  
- 📊 **Market research** with real-time pricing data
- 🏪 **Retailers** with inventory and pricing optimization
- 📱 **Mobile apps** with product lookup and price comparison
- 🤖 **Business intelligence** with automated price monitoring

### Why Choose ShopSavvy Data API?
- ✅ **Trusted by millions** - Proven at scale since 2008
- ✅ **Comprehensive coverage** - 1000+ retailers, millions of products  
- ✅ **Real-time accuracy** - Fresh data updated continuously
- ✅ **Developer-friendly** - Easy integration, great documentation
- ✅ **Reliable infrastructure** - 99.9% uptime, enterprise-grade
- ✅ **Flexible pricing** - Plans for every use case and budget

---

**Ready to get started?** [Sign up for your API key](https://shopsavvy.com/data) • **Need help?** [Contact us](mailto:business@shopsavvy.com)
