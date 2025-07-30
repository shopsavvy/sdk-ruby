# frozen_string_literal: true

module ShopsavvyDataApi
  # Configuration for ShopSavvy Data API client
  class Configuration
    attr_accessor :api_key, :base_url, :timeout

    def initialize(api_key:, base_url: "https://api.shopsavvy.com/v1", timeout: 30)
      @api_key = api_key
      @base_url = base_url
      @timeout = timeout

      validate_api_key!
    end

    private

    def validate_api_key!
      raise ConfigurationError, "API key is required" if api_key.nil? || api_key.empty?

      unless api_key.match?(/\Ass_(live|test)_[a-zA-Z0-9]+\z/)
        raise ConfigurationError, "Invalid API key format. API keys should start with ss_live_ or ss_test_"
      end
    end
  end

  # Product details from ShopSavvy API
  class ProductDetails
    attr_reader :product_id, :name, :brand, :category, :image_url, :barcode, 
                :asin, :model, :mpn, :description, :identifiers

    def initialize(data)
      @product_id = data["product_id"]
      @name = data["name"]
      @brand = data["brand"]
      @category = data["category"]
      @image_url = data["image_url"]
      @barcode = data["barcode"]
      @asin = data["asin"]
      @model = data["model"]
      @mpn = data["mpn"]
      @description = data["description"]
      @identifiers = data["identifiers"] || {}
    end

    def to_h
      {
        product_id: product_id,
        name: name,
        brand: brand,
        category: category,
        image_url: image_url,
        barcode: barcode,
        asin: asin,
        model: model,
        mpn: mpn,
        description: description,
        identifiers: identifiers
      }
    end
  end

  # Product offer from a retailer
  class Offer
    attr_reader :offer_id, :retailer, :price, :currency, :availability, 
                :condition, :url, :shipping, :last_updated

    def initialize(data)
      @offer_id = data["offer_id"]
      @retailer = data["retailer"]
      @price = data["price"].to_f
      @currency = data["currency"] || "USD"
      @availability = data["availability"]
      @condition = data["condition"]
      @url = data["url"]
      @shipping = data["shipping"]&.to_f
      @last_updated = data["last_updated"]
    end

    def to_h
      {
        offer_id: offer_id,
        retailer: retailer,
        price: price,
        currency: currency,
        availability: availability,
        condition: condition,
        url: url,
        shipping: shipping,
        last_updated: last_updated
      }
    end

    def in_stock?
      availability == "in_stock"
    end

    def out_of_stock?
      availability == "out_of_stock"
    end

    def limited_stock?
      availability == "limited_stock"
    end

    def new_condition?
      condition == "new"
    end

    def used_condition?
      condition == "used"
    end

    def refurbished_condition?
      condition == "refurbished"
    end
  end

  # Historical price data point
  class PriceHistoryEntry
    attr_reader :date, :price, :availability

    def initialize(data)
      @date = data["date"]
      @price = data["price"].to_f
      @availability = data["availability"]
    end

    def to_h
      {
        date: date,
        price: price,
        availability: availability
      }
    end
  end

  # Offer with historical price data
  class OfferWithHistory < Offer
    attr_reader :price_history

    def initialize(data)
      super(data)
      @price_history = (data["price_history"] || []).map { |entry| PriceHistoryEntry.new(entry) }
    end

    def to_h
      super.merge(price_history: price_history.map(&:to_h))
    end

    def min_price
      return nil if price_history.empty?

      price_history.map(&:price).min
    end

    def max_price
      return nil if price_history.empty?

      price_history.map(&:price).max
    end

    def average_price
      return nil if price_history.empty?

      prices = price_history.map(&:price)
      prices.sum.to_f / prices.length
    end
  end

  # Scheduled product monitoring information
  class ScheduledProduct
    attr_reader :product_id, :identifier, :frequency, :retailer, 
                :created_at, :last_refreshed

    def initialize(data)
      @product_id = data["product_id"]
      @identifier = data["identifier"]
      @frequency = data["frequency"]
      @retailer = data["retailer"]
      @created_at = data["created_at"]
      @last_refreshed = data["last_refreshed"]
    end

    def to_h
      {
        product_id: product_id,
        identifier: identifier,
        frequency: frequency,
        retailer: retailer,
        created_at: created_at,
        last_refreshed: last_refreshed
      }
    end

    def hourly?
      frequency == "hourly"
    end

    def daily?
      frequency == "daily"
    end

    def weekly?
      frequency == "weekly"
    end
  end

  # API usage information
  class UsageInfo
    attr_reader :credits_used, :credits_remaining, :credits_total,
                :billing_period_start, :billing_period_end, :plan_name

    def initialize(data)
      @credits_used = data["credits_used"].to_i
      @credits_remaining = data["credits_remaining"].to_i
      @credits_total = data["credits_total"].to_i
      @billing_period_start = data["billing_period_start"]
      @billing_period_end = data["billing_period_end"]
      @plan_name = data["plan_name"]
    end

    def to_h
      {
        credits_used: credits_used,
        credits_remaining: credits_remaining,
        credits_total: credits_total,
        billing_period_start: billing_period_start,
        billing_period_end: billing_period_end,
        plan_name: plan_name
      }
    end

    def credits_percentage_used
      return 0 if credits_total.zero?

      (credits_used.to_f / credits_total * 100).round(2)
    end

    def credits_percentage_remaining
      100 - credits_percentage_used
    end
  end

  # Standard API response wrapper
  class APIResponse
    attr_reader :success, :data, :message, :credits_used, :credits_remaining

    def initialize(response_data, data_class: nil)
      @success = response_data["success"]
      @message = response_data["message"]
      @credits_used = response_data["credits_used"]
      @credits_remaining = response_data["credits_remaining"]

      @data = if data_class && response_data["data"]
                parse_data(response_data["data"], data_class)
              else
                response_data["data"]
              end
    end

    def success?
      success == true
    end

    def failure?
      !success?
    end

    def to_h
      {
        success: success,
        data: data.respond_to?(:to_h) ? data.to_h : data,
        message: message,
        credits_used: credits_used,
        credits_remaining: credits_remaining
      }
    end

    private

    def parse_data(data, data_class)
      case data
      when Array
        data.map { |item| data_class.new(item) }
      when Hash
        if data.keys.all? { |key| key.is_a?(String) } && 
           data.values.all? { |value| value.is_a?(Array) }
          # Handle batch responses like {"identifier1" => [offers], "identifier2" => [offers]}
          data.transform_values { |items| items.map { |item| data_class.new(item) } }
        else
          data_class.new(data)
        end
      else
        data
      end
    end
  end
end