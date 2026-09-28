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
  #   puts product.data[0].title
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

    # Search for products by keyword
    #
    # @param query [String] Search query or keyword (e.g., "iphone 15 pro", "samsung tv")
    # @param limit [Integer] Maximum number of results (default: 20)
    # @param offset [Integer] Pagination offset (default: 0)
    # @return [ProductSearchResult] Search results with pagination info
    #
    # @example
    #   results = client.search_products("iphone 15 pro", limit: 10)
    #   results.data.each { |product| puts product.title }
    def search_products(query, limit: nil, offset: nil)
      params = { q: query }
      params[:limit] = limit if limit
      params[:offset] = offset if offset

      response = make_request(:get, "products/search", params: params)
      ProductSearchResult.new(response)
    end

    # Look up product details by identifier
    #
    # @param identifier [String] Product identifier (barcode, ASIN, URL, model number, or ShopSavvy product ID)
    # @param format [String, nil] Response format ('json' or 'csv')
    # @return [APIResponse<Array<ProductDetails>>] Product details (as array, even for single identifier)
    #
    # @example
    #   product = client.get_product_details("012345678901")
    #   puts product.data[0].title
    def get_product_details(identifier, format: nil)
      params = { ids: identifier }
      params[:format] = format if format

      response = make_request(:get, "products", params: params)
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
    #   products.data.each { |product| puts product.title }
    def get_product_details_batch(identifiers, format: nil)
      params = { ids: identifiers.join(",") }
      params[:format] = format if format

      response = make_request(:get, "products", params: params)
      APIResponse.new(response, data_class: ProductDetails)
    end

    # Get current offers for a product
    #
    # @param identifier [String] Product identifier
    # @param retailer [String, nil] Optional retailer to filter by
    # @param format [String, nil] Response format ('json' or 'csv')
    # @return [APIResponse<Array<ProductWithOffers>>] Products with their offers
    #
    # @example
    #   result = client.get_current_offers("012345678901")
    #   result.data.each do |product|
    #     puts "Product: #{product.title}"
    #     product.offers.each { |offer| puts "  #{offer.retailer}: $#{offer.price}" }
    #   end
    def get_current_offers(identifier, retailer: nil, format: nil)
      params = { ids: identifier }
      params[:retailer] = retailer if retailer
      params[:format] = format if format

      response = make_request(:get, "products/offers", params: params)
      APIResponse.new(response, data_class: ProductWithOffers)
    end

    # Get current offers for multiple products
    #
    # @param identifiers [Array<String>] Array of product identifiers
    # @param retailer [String, nil] Optional retailer to filter by
    # @param format [String, nil] Response format ('json' or 'csv')
    # @return [APIResponse<Array<ProductWithOffers>>] Products with their offers
    def get_current_offers_batch(identifiers, retailer: nil, format: nil)
      params = { ids: identifiers.join(",") }
      params[:retailer] = retailer if retailer
      params[:format] = format if format

      response = make_request(:get, "products/offers", params: params)
      APIResponse.new(response, data_class: ProductWithOffers)
    end

    # Get price history for a product
    #
    # @param identifier [String] Product identifier
    # @param start_date [String] Start date (YYYY-MM-DD format)
    # @param end_date [String] End date (YYYY-MM-DD format)
    # @param retailer [String, nil] Optional retailer to filter by
    # @param format [String, nil] Response format ('json' or 'csv')
    # @return [APIResponse<Array<ProductWithOfferHistory>>] One entry per product found, each
    #   carrying its offers, each offer carrying its +history+ points (newest first)
    #
    # @example
    #   result = client.get_price_history("012345678901", "2024-01-01", "2024-01-31")
    #   result.data.each do |product|
    #     puts product.title
    #     product.offers.each do |offer|
    #       puts "  #{offer.retailer}: #{offer.history.length} price points, low $#{offer.min_price}"
    #     end
    #   end
    def get_price_history(identifier, start_date, end_date, retailer: nil, format: nil)
      # Wire params are :start/:end — what GET /products/offers/history reads,
      # and what the OpenAPI spec and public docs document. The old
      # :start_date/:end_date names came from the MCP tool's argument
      # convention (a different interface entirely) and 400'd every call.
      params = {
        ids: identifier,
        start: start_date,
        end: end_date
      }
      params[:retailer] = retailer if retailer
      params[:format] = format if format

      response = make_request(:get, "products/offers/history", params: params)
      APIResponse.new(response, data_class: ProductWithOfferHistory)
    end

    # Schedule product monitoring
    #
    # @param identifier [String] Product identifier
    # @param frequency [String] How often to refresh ('hourly', 'daily', 'weekly')
    # @param retailer [String, nil] Optional retailer to monitor
    # @return [APIResponse<Array<ScheduledProduct>>] The scheduled products (every product
    #   field plus +schedule+, and +retailer+ when one was given)
    #
    # @example
    #   result = client.schedule_product_monitoring("012345678901", "daily")
    #   result.data.each { |product| puts "#{product.title}: #{product.schedule}" }
    def schedule_product_monitoring(identifier, frequency, retailer: nil)
      schedule_products([identifier], frequency, retailer: retailer)
    end

    # Schedule monitoring for multiple products
    #
    # @param identifiers [Array<String>] Array of product identifiers
    # @param frequency [String] How often to refresh ('hourly', 'daily', 'weekly')
    # @param retailer [String, nil] Optional retailer to monitor
    # @return [APIResponse<Array<ScheduledProduct>>] The scheduled products (every product
    #   field plus +schedule+, and +retailer+ when one was given)
    def schedule_product_monitoring_batch(identifiers, frequency, retailer: nil)
      schedule_products(identifiers, frequency, retailer: retailer)
    end

    # Get all scheduled products
    #
    # @return [APIResponse<Array<ScheduledProduct>>] Every scheduled product (product fields
    #   plus +schedule+, which is nil for an interval with no Data API label, and +retailer+
    #   when the schedule is limited to one retailer)
    #
    # @example
    #   scheduled = client.get_scheduled_products
    #   scheduled.data.each { |product| puts "#{product.title}: #{product.schedule}" }
    def get_scheduled_products
      response = make_request(:get, "products/scheduled")
      APIResponse.new(response, data_class: ScheduledProduct)
    end

    # Remove product from monitoring schedule
    #
    # @param identifier [String] Product identifier to remove
    # @return [APIResponse] Removal confirmation: +success?+, +message+ and +meta+. The
    #   server sends no +data+, so +data+ is always nil.
    #
    # @example
    #   result = client.remove_product_from_schedule("012345678901")
    #   puts result.message if result.success?
    def remove_product_from_schedule(identifier)
      remove_products_from_schedule([identifier])
    end

    # Remove multiple products from monitoring schedule
    #
    # @param identifiers [Array<String>] Array of product identifiers to remove
    # @return [APIResponse] Removal confirmation: +success?+, +message+ and +meta+ (+data+ is nil)
    def remove_products_from_schedule(identifiers)
      # DELETE /products/scheduled reads only the `ids` query parameter.
      response = make_request(:delete, "products/scheduled", params: { ids: identifiers.join(",") })
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
      response = make_request(:get, "usage")
      APIResponse.new(response, data_class: UsageInfo)
    end

    # Browse current shopping deals
    # @param sort [String] Sort algorithm: hot, new, top-hour, top-day, top-week
    # @param limit [Integer] Results per page (1-100)
    # @param offset [Integer] Pagination offset
    # @param options [Hash] Additional filters (category, retailer, tag, min_price, max_price, grade)
    # @return [Hash] Deals response with deals array and pagination
    def get_deals(sort: "hot", limit: 25, offset: 0, **options)
      params = { sort: sort, limit: limit, offset: offset }.merge(options).compact
      make_request(:get, "deals", params: params)
    end

    # Get TLDR review for a product (pros, cons, scores)
    # @param identifier [String] Product identifier (barcode, ASIN, URL, model number)
    # @return [Hash] Review response with review data or null
    def get_product_review(identifier)
      make_request(:get, "products/reviews", params: { id: identifier })
    end

    # Look up multiple products at once (sync for <=20, async for >20)
    # @param identifiers [Array<String>] Product identifiers (max 100)
    # @param include [Array<String>] Optional extras: ["offers"], ["reviews"]
    def batch_lookup(identifiers, include: nil)
      body = { identifiers: identifiers }
      body[:include] = include if include
      make_request(:post, "products/batch", body: body)
    end

    # Poll for async batch job results
    def get_batch_status(batch_id)
      make_request(:get, "batch/#{batch_id}")
    end

    def create_webhook(url, events:)
      make_request(:post, "webhooks", body: { url: url, events: events })
    end

    def list_webhooks
      make_request(:get, "webhooks")
    end

    def test_webhook(webhook_id)
      make_request(:post, "webhooks/#{webhook_id}/test")
    end

    # Update a webhook. All keyword arguments are optional, but at least one
    # of url:, events:, or is_active: must be provided.
    def update_webhook(webhook_id, url: nil, events: nil, is_active: nil)
      if url.nil? && events.nil? && is_active.nil?
        raise ArgumentError, "update_webhook requires at least one of url:, events:, or is_active:"
      end
      body = {}
      body[:url] = url unless url.nil?
      body[:events] = events unless events.nil?
      body[:is_active] = is_active unless is_active.nil?
      make_request(:put, "webhooks/#{webhook_id}", body: body)
    end

    def delete_webhook(webhook_id)
      make_request(:delete, "webhooks/#{webhook_id}")
    end

    private

    # PUT /products/scheduled reads ONLY query parameters (ids, schedule, retailer). This
    # used to POST a JSON body of {identifier(s), frequency, retailer} to /products/schedule;
    # the server ignores request bodies on this route, so every call failed with
    # "An 'ids' query parameter is required" (and the frequency and retailer never arrived).
    def schedule_products(identifiers, frequency, retailer: nil)
      params = { ids: identifiers.join(","), schedule: frequency }
      params[:retailer] = retailer if retailer

      response = make_request(:put, "products/scheduled", params: params)
      APIResponse.new(response, data_class: ScheduledProduct)
    end

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
      # run_request so that `params` is ALWAYS the query string. Faraday's verb helpers
      # disagree about their second positional argument: get/delete treat it as query
      # params, but post/put/patch treat it as the request BODY.
      response = @connection.run_request(method, path, nil, nil) do |req|
        req.params.update(params) if params
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
