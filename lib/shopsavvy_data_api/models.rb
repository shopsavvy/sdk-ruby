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

  # API response metadata containing credit usage info
  class APIMeta
    attr_reader :credits_used, :credits_remaining, :rate_limit_remaining

    def initialize(data)
      @credits_used = data["credits_used"].to_i
      @credits_remaining = data["credits_remaining"].to_i
      @rate_limit_remaining = data["rate_limit_remaining"]&.to_i
    end

    def to_h
      {
        credits_used: credits_used,
        credits_remaining: credits_remaining,
        rate_limit_remaining: rate_limit_remaining
      }
    end
  end

  # Product details from ShopSavvy API
  #
  # score: expert quality scores on a 0-1 scale (multiply by 10 or 100 for
  # display) — "overall", "customer", "professional", plus an "aspects" hash
  # keyed by free-form aspect names from the product's professional reviews.
  class ProductDetails
    attr_reader :title, :shopsavvy, :brand, :category, :images, :barcode,
                :amazon, :model, :mpn, :color,
                :title_short, :slug, :description, :categories, :attributes,
                :rating, :score, :keywords, :identifiers

    def initialize(data)
      @title = data["title"]
      @shopsavvy = data["shopsavvy"]
      @brand = data["brand"]
      @category = data["category"]
      @images = data["images"] || []
      @barcode = data["barcode"]
      @amazon = data["amazon"]
      @model = data["model"]
      @mpn = data["mpn"]
      @color = data["color"]
      @title_short = data["title_short"]
      @slug = data["slug"]
      @description = data["description"]
      @categories = data["categories"]
      @attributes = data["attributes"]
      @rating = data["rating"]
      @score = data["score"]
      @keywords = data["keywords"]
      @identifiers = data["identifiers"]
    end

    # @deprecated Use `title` instead
    def name
      title
    end

    # @deprecated Use `shopsavvy` instead
    def product_id
      shopsavvy
    end

    # @deprecated Use `amazon` instead
    def asin
      amazon
    end

    # @deprecated Use `images[0]` instead
    def image_url
      images&.first
    end

    def to_h
      {
        title: title,
        shopsavvy: shopsavvy,
        brand: brand,
        category: category,
        images: images,
        barcode: barcode,
        amazon: amazon,
        model: model,
        mpn: mpn,
        color: color
      }
    end
  end

  # Product with nested offers (returned by offers endpoint)
  class ProductWithOffers < ProductDetails
    attr_reader :offers

    def initialize(data)
      super(data)
      @offers = (data["offers"] || []).map { |offer| Offer.new(offer) }
    end

    def to_h
      super.merge(offers: offers.map(&:to_h))
    end
  end

  # Product offer from a retailer
  class Offer
    attr_reader :id, :retailer, :price, :currency, :availability,
                :condition, :URL, :seller, :timestamp, :history

    def initialize(data)
      @id = data["id"]
      @retailer = data["retailer"]
      @price = data["price"]&.to_f
      @currency = data["currency"] || "USD"
      @availability = data["availability"]
      @condition = data["condition"]
      @URL = data["URL"]
      @seller = data["seller"]
      @timestamp = data["timestamp"]
      @history = (data["history"] || []).map { |entry| PriceHistoryEntry.new(entry) }
    end

    # @deprecated Use `id` instead
    def offer_id
      id
    end

    # @deprecated Use `URL` instead
    def url
      URL
    end

    # @deprecated Use `timestamp` instead
    def last_updated
      timestamp
    end

    def to_h
      {
        id: id,
        retailer: retailer,
        price: price,
        currency: currency,
        availability: availability,
        condition: condition,
        URL: URL,
        seller: seller,
        timestamp: timestamp,
        history: history.map(&:to_h)
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

  # Current billing period details
  class UsagePeriod
    attr_reader :start_date, :end_date, :credits_used, :credits_limit,
                :credits_remaining, :requests_made

    def initialize(data)
      @start_date = data["start_date"]
      @end_date = data["end_date"]
      @credits_used = data["credits_used"].to_i
      @credits_limit = data["credits_limit"].to_i
      @credits_remaining = data["credits_remaining"].to_i
      @requests_made = data["requests_made"].to_i
    end

    def to_h
      {
        start_date: start_date,
        end_date: end_date,
        credits_used: credits_used,
        credits_limit: credits_limit,
        credits_remaining: credits_remaining,
        requests_made: requests_made
      }
    end
  end

  # API usage information
  class UsageInfo
    attr_reader :current_period, :usage_percentage

    def initialize(data)
      @current_period = UsagePeriod.new(data["current_period"] || {})
      @usage_percentage = data["usage_percentage"]&.to_f || 0
    end

    # @deprecated Use `current_period.credits_used` instead
    def credits_used
      current_period.credits_used
    end

    # @deprecated Use `current_period.credits_remaining` instead
    def credits_remaining
      current_period.credits_remaining
    end

    # @deprecated Use `current_period.credits_limit` instead
    def credits_total
      current_period.credits_limit
    end

    # @deprecated Use `current_period.start_date` instead
    def billing_period_start
      current_period.start_date
    end

    # @deprecated Use `current_period.end_date` instead
    def billing_period_end
      current_period.end_date
    end

    def to_h
      {
        current_period: current_period.to_h,
        usage_percentage: usage_percentage
      }
    end

    def credits_percentage_used
      return 0 if current_period.credits_limit.zero?

      (current_period.credits_used.to_f / current_period.credits_limit * 100).round(2)
    end

    def credits_percentage_remaining
      100 - credits_percentage_used
    end
  end

  # Pagination info for search results
  class PaginationInfo
    attr_reader :total, :limit, :offset, :returned

    def initialize(data)
      @total = data["total"].to_i
      @limit = data["limit"].to_i
      @offset = data["offset"].to_i
      @returned = data["returned"].to_i
    end

    def to_h
      {
        total: total,
        limit: limit,
        offset: offset,
        returned: returned
      }
    end
  end

  # Standard API response wrapper
  class APIResponse
    attr_reader :success, :data, :message, :meta

    def initialize(response_data, data_class: nil)
      @success = response_data["success"]
      @message = response_data["message"]
      @meta = response_data["meta"] ? APIMeta.new(response_data["meta"]) : nil

      @data = if data_class && response_data["data"]
                parse_data(response_data["data"], data_class)
              else
                response_data["data"]
              end
    end

    def credits_used
      meta&.credits_used || 0
    end

    def credits_remaining
      meta&.credits_remaining || 0
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
        meta: meta&.to_h
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

  # Product search result with pagination
  class ProductSearchResult
    attr_reader :success, :data, :pagination, :meta

    def initialize(response_data)
      @success = response_data["success"]
      @meta = response_data["meta"] ? APIMeta.new(response_data["meta"]) : nil
      @pagination = response_data["pagination"] ? PaginationInfo.new(response_data["pagination"]) : nil
      @data = (response_data["data"] || []).map { |item| ProductDetails.new(item) }
    end

    def credits_used
      meta&.credits_used || 0
    end

    def credits_remaining
      meta&.credits_remaining || 0
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
        data: data.map(&:to_h),
        pagination: pagination&.to_h,
        meta: meta&.to_h
      }
    end
  end

  # Deal with expert grading
  class Deal
    attr_reader :path, :title, :subtitle, :description, :emoji, :grade,
                :pricing, :retailer, :product, :url, :image, :votes,
                :comment_count, :tags, :expires_at, :created_at

    def initialize(data)
      @path = data["path"]
      @title = data["title"]
      @subtitle = data["subtitle"]
      @description = data["description"]
      @emoji = data["emoji"]
      @grade = data["grade"]
      @pricing = data["pricing"]
      @retailer = data["retailer"]
      @product = data["product"]
      @url = data["url"]
      @image = data["image"]
      @votes = data["votes"]
      @comment_count = data["comment_count"].to_i
      @tags = data["tags"]
      @expires_at = data["expires_at"]
      @created_at = data["created_at"]
    end
  end

  # TLDR product review
  #
  # scores: expert quality scores on a 0-1 scale (multiply by 10 or 100 for
  # display) — "overall", "customer", "professional", plus an "aspects" hash
  # keyed by free-form aspect names from the product's professional reviews.
  class TLDRReview
    attr_reader :slug, :headline, :pros, :cons, :bottom_line, :scores

    def initialize(data)
      @slug = data["slug"]
      @headline = data["headline"]
      @pros = data["pros"] || []
      @cons = data["cons"] || []
      @bottom_line = data["bottom_line"]
      @scores = data["scores"]
    end
  end
end
