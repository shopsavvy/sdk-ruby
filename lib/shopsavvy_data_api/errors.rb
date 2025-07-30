# frozen_string_literal: true

module ShopsavvyDataApi
  # Base error class for all ShopSavvy API errors
  class Error < StandardError
    attr_reader :status_code, :response_data

    def initialize(message, status_code: nil, response_data: nil)
      super(message)
      @status_code = status_code
      @response_data = response_data
    end
  end

  # API-related errors
  class APIError < Error; end

  # Authentication failed (invalid API key, etc.)
  class AuthenticationError < APIError; end

  # Rate limit exceeded
  class RateLimitError < APIError; end

  # Resource not found (product, etc.)
  class NotFoundError < APIError; end

  # Request validation failed
  class ValidationError < APIError; end

  # Request timeout
  class TimeoutError < Error; end

  # Network connection error
  class NetworkError < Error; end

  # Configuration error
  class ConfigurationError < Error; end
end