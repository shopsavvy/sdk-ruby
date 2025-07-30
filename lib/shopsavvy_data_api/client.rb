# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module ShopsavvyDataApi
  # Official Ruby client for ShopSavvy Data API
  #
  # Provides access to product data, pricing information, and price history
  # across thousands of retailers and millions of products.
  #
  # @example Basic usage
  #   client = ShopsavvyDataApi::Client.new(api_key: "ss_live_your_api_key_here")
  #   product = client.get_product_details("012345678901")
  #   puts product.data.name
  #
  # @example Using configuration
  #   config = ShopsavvyDataApi::Configuration.new(
  #     api_key: "ss_live_your_api_key_here",
  #     timeout: 60
  #   )
  #   client = ShopsavvyDataApi::Client.new(config)
  class Client
    attr_reader :config

    # Initialize a new client
    #
    # @param config [Configuration, Hash] Configuration object or hash with :api_key
    # @param api_key [String] API key (alternative to config parameter)
    # @param base_url [String] Base URL for API (default: https://api.shopsavvy.com/v1)
    # @param timeout [Integer] Request timeout in seconds (default: 30)
    def initialize(config = nil, api_key: nil, base_url: nil, timeout: nil)
      @config = if config.is_a?(Configuration)
                  config
                elsif config.is_a?(Hash)
                  Configuration.new(**config)
                elsif api_key
                  Configuration.new(
                    api_key: api_key,
                    base_url: base_url || "https://api.shopsavvy.com/v1",
                    timeout: timeout || 30
                  )
                else
                  raise ConfigurationError, "Either config or api_key must be provided"
                end

      @connection = build_connection
    end

    # Look up product details by identifier
    #
    # @param identifier [String] Product identifier (barcode, ASIN, URL, model number, or ShopSavvy product ID)
    # @param format [String, nil] Response format ('json' or 'csv')
    # @return [APIResponse<ProductDetails>] Product details
    #
    # @example
    #   product = client.get_product_details("012345678901")
    #   puts product.data.name
    def get_product_details(identifier, format: nil)
      params = { identifier: identifier }
      params[:format] = format if format

      response = make_request(:get, "/products/details", params: params)
      APIResponse.new(response, data_class: ProductDetails)
    end

    # Look up details for multiple products
    #
    # @param identifiers [Array<String>] Array of product identifiers
    # @param format [String, nil] Response format ('json' or 'csv')
    # @return [APIResponse<Array<ProductDetails>>] Array of product details
    #
    # @example
    #   products = client.get_product_details_batch(["012345678901", "B08N5WRWNW"])
    #   products.data.each { |product| puts product.name }
    def get_product_details_batch(identifiers, format: nil)
      params = { identifiers: identifiers.join(",") }
      params[:format] = format if format

      response = make_request(:get, "/products/details", params: params)
      APIResponse.new(response, data_class: ProductDetails)
    end

    # Get current offers for a product
    #
    # @param identifier [String] Product identifier
    # @param retailer [String, nil] Optional retailer to filter by
    # @param format [String, nil] Response format ('json' or 'csv')
    # @return [APIResponse<Array<Offer>>] Current offers
    #
    # @example
    #   offers = client.get_current_offers("012345678901")
    #   offers.data.each { |offer| puts "#{offer.retailer}: $#{offer.price}" }
    def get_current_offers(identifier, retailer: nil, format: nil)
      params = { identifier: identifier }
      params[:retailer] = retailer if retailer
      params[:format] = format if format

      response = make_request(:get, "/products/offers", params: params)
      APIResponse.new(response, data_class: Offer)
    end

    # Get current offers for multiple products
    #
    # @param identifiers [Array<String>] Array of product identifiers
    # @param retailer [String, nil] Optional retailer to filter by
    # @param format [String, nil] Response format ('json' or 'csv')
    # @return [APIResponse<Hash<String, Array<Offer>>>] Hash mapping identifiers to their offers
    def get_current_offers_batch(identifiers, retailer: nil, format: nil)
      params = { identifiers: identifiers.join(",") }
      params[:retailer] = retailer if retailer
      params[:format] = format if format

      response = make_request(:get, "/products/offers", params: params)
      APIResponse.new(response, data_class: Offer)
    end

    # Get price history for a product
    #
    # @param identifier [String] Product identifier
    # @param start_date [String] Start date (YYYY-MM-DD format)
    # @param end_date [String] End date (YYYY-MM-DD format)
    # @param retailer [String, nil] Optional retailer to filter by
    # @param format [String, nil] Response format ('json' or 'csv')
    # @return [APIResponse<Array<OfferWithHistory>>] Offers with price history
    #
    # @example
    #   history = client.get_price_history("012345678901", "2024-01-01", "2024-01-31")
    #   history.data.each do |offer|
    #     puts "#{offer.retailer}: #{offer.price_history.length} price points"
    #   end
    def get_price_history(identifier, start_date, end_date, retailer: nil, format: nil)
      params = {
        identifier: identifier,
        start_date: start_date,
        end_date: end_date
      }
      params[:retailer] = retailer if retailer
      params[:format] = format if format

      response = make_request(:get, "/products/history", params: params)
      APIResponse.new(response, data_class: OfferWithHistory)
    end

    # Schedule product monitoring
    #
    # @param identifier [String] Product identifier
    # @param frequency [String] How often to refresh ('hourly', 'daily', 'weekly')
    # @param retailer [String, nil] Optional retailer to monitor
    # @return [APIResponse<Hash>] Scheduling confirmation
    #
    # @example
    #   result = client.schedule_product_monitoring("012345678901", "daily")
    #   puts "Scheduled: #{result.data['scheduled']}"
    def schedule_product_monitoring(identifier, frequency, retailer: nil)
      body = {
        identifier: identifier,
        frequency: frequency
      }
      body[:retailer] = retailer if retailer

      response = make_request(:post, "/products/schedule", body: body)
      APIResponse.new(response)
    end

    # Schedule monitoring for multiple products
    #
    # @param identifiers [Array<String>] Array of product identifiers
    # @param frequency [String] How often to refresh ('hourly', 'daily', 'weekly')
    # @param retailer [String, nil] Optional retailer to monitor
    # @return [APIResponse<Array<Hash>>] Scheduling confirmation for all products
    def schedule_product_monitoring_batch(identifiers, frequency, retailer: nil)
      body = {
        identifiers: identifiers.join(","),
        frequency: frequency
      }
      body[:retailer] = retailer if retailer

      response = make_request(:post, "/products/schedule", body: body)
      APIResponse.new(response)
    end

    # Get all scheduled products
    #
    # @return [APIResponse<Array<ScheduledProduct>>] List of scheduled products
    #
    # @example
    #   scheduled = client.get_scheduled_products
    #   puts "Monitoring #{scheduled.data.length} products"
    def get_scheduled_products
      response = make_request(:get, "/products/scheduled")
      APIResponse.new(response, data_class: ScheduledProduct)
    end

    # Remove product from monitoring schedule
    #
    # @param identifier [String] Product identifier to remove
    # @return [APIResponse<Hash>] Removal confirmation
    #
    # @example
    #   result = client.remove_product_from_schedule("012345678901")
    #   puts "Removed: #{result.data['removed']}"
    def remove_product_from_schedule(identifier)
      body = { identifier: identifier }

      response = make_request(:delete, "/products/schedule", body: body)
      APIResponse.new(response)
    end

    # Remove multiple products from monitoring schedule
    #
    # @param identifiers [Array<String>] Array of product identifiers to remove
    # @return [APIResponse<Array<Hash>>] Removal confirmation for all products
    def remove_products_from_schedule(identifiers)
      body = { identifiers: identifiers.join(",") }

      response = make_request(:delete, "/products/schedule", body: body)
      APIResponse.new(response)
    end

    # Get API usage information
    #
    # @return [APIResponse<UsageInfo>] Current usage and credit information
    #
    # @example
    #   usage = client.get_usage
    #   puts "Credits remaining: #{usage.data.credits_remaining}"
    def get_usage
      response = make_request(:get, "/usage")
      APIResponse.new(response, data_class: UsageInfo)
    end

    private

    def build_connection
      Faraday.new(
        url: config.base_url,
        headers: {
          "Authorization" => "Bearer #{config.api_key}",
          "Content-Type" => "application/json",
          "User-Agent" => "ShopSavvy-Ruby-SDK/#{VERSION}"
        }
      ) do |f|
        f.request :json
        f.request :retry, max: 3, interval: 0.5, backoff_factor: 2
        f.response :json
        f.adapter Faraday.default_adapter
        f.options.timeout = config.timeout
      end
    end

    def make_request(method, path, params: nil, body: nil)
      response = @connection.public_send(method, path, params) do |req|
        req.body = body.to_json if body
      end

      handle_response(response)
    rescue Faraday::TimeoutError => e
      raise TimeoutError, "Request timeout after #{config.timeout} seconds: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      raise NetworkError, "Network connection failed: #{e.message}"
    rescue Faraday::Error => e
      raise APIError, "Request failed: #{e.message}"
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 401
        raise AuthenticationError.new(
          "Authentication failed. Check your API key.",
          status_code: response.status,
          response_data: response.body
        )
      when 404
        raise NotFoundError.new(
          "Resource not found",
          status_code: response.status,
          response_data: response.body
        )
      when 422
        raise ValidationError.new(
          "Request validation failed. Check your parameters.",
          status_code: response.status,
          response_data: response.body
        )
      when 429
        raise RateLimitError.new(
          "Rate limit exceeded. Please slow down your requests.",
          status_code: response.status,
          response_data: response.body
        )
      else
        error_message = if response.body.is_a?(Hash) && response.body["error"]
                          response.body["error"]
                        else
                          "HTTP #{response.status}: #{response.reason_phrase}"
                        end

        raise APIError.new(
          error_message,
          status_code: response.status,
          response_data: response.body
        )
      end
    end
  end
end