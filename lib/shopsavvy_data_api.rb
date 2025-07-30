# frozen_string_literal: true

require_relative "shopsavvy_data_api/version"
require_relative "shopsavvy_data_api/errors"
require_relative "shopsavvy_data_api/models"
require_relative "shopsavvy_data_api/client"

# Official Ruby SDK for ShopSavvy Data API
#
# This gem provides a convenient interface to interact with the ShopSavvy Data API,
# allowing you to access product data, pricing information, and price history
# across thousands of retailers and millions of products.
#
# @example Basic usage
#   client = ShopsavvyDataApi.new(api_key: "ss_live_your_api_key_here")
#   product = client.get_product_details("012345678901")
#   puts product.data.name
#
# @see https://shopsavvy.com/data
module ShopsavvyDataApi
  class << self
    # Create a new ShopSavvy Data API client
    #
    # @param api_key [String] Your ShopSavvy API key
    # @param base_url [String] Base URL for API (default: https://api.shopsavvy.com/v1)
    # @param timeout [Integer] Request timeout in seconds (default: 30)
    # @return [Client] API client instance
    #
    # @example
    #   client = ShopsavvyDataApi.new(api_key: "ss_live_your_api_key_here")
    #   product = client.get_product_details("012345678901")
    #   puts product.data.name
    def new(api_key:, **options)
      Client.new(api_key: api_key, **options)
    end

    # Create a client with configuration object
    #
    # @param config [Configuration] Configuration object
    # @return [Client] API client instance
    #
    # @example
    #   config = ShopsavvyDataApi::Configuration.new(api_key: "ss_live_key", timeout: 60)
    #   client = ShopsavvyDataApi.with_config(config)
    def with_config(config)
      Client.new(config)
    end
  end
end