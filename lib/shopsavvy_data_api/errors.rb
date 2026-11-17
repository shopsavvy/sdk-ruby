# frozen_string_literal: true

module ShopsavvyDataApi
  # Base error class for all ShopSavvy API errors.
  #
  # API errors (APIError and subclasses) carry the API's structured detail. Branch on the
  # class or on +code+, not on +status_code+: ERR_RATE_LIMIT and ERR_CREDITS_EXHAUSTED both
  # arrive as HTTP 429.
  class Error < StandardError
    # @return [Integer, nil] HTTP status
    attr_reader :status_code
    # @return [Hash, String, nil] decoded response body
    attr_reader :response_data
    # @return [String, nil] error_detail.code, e.g. "ERR_RATE_LIMIT"; nil when the server sent none
    attr_reader :code
    # @return [String, nil] one-line fix from error_detail.action
    attr_reader :action
    # @return [String, nil] link to the documentation for this code
    attr_reader :docs_url
    # @return [String, nil] meta.request_id; quote it in support requests
    attr_reader :request_id
    # @return [Integer, nil] seconds from the Retry-After header; only meaningful for ERR_RATE_LIMIT
    attr_reader :retry_after_seconds

    # rubocop:disable Metrics/ParameterLists
    def initialize(message, status_code: nil, response_data: nil, code: nil, action: nil,
                   docs_url: nil, request_id: nil, retry_after_seconds: nil)
      super(message)
      @status_code = status_code
      @response_data = response_data
      @code = code
      @action = action
      @docs_url = docs_url
      @request_id = request_id
      @retry_after_seconds = retry_after_seconds
    end
    # rubocop:enable Metrics/ParameterLists
  end

  # API-related errors
  class APIError < Error; end

  # Authentication failed (ERR_AUTH_MISSING / ERR_AUTH_INVALID / ERR_AUTH_REVOKED, HTTP 401)
  class AuthenticationError < APIError; end

  # ERR_RATE_LIMIT, or a 429 with no code (older server): wait retry_after_seconds, then retry
  class RateLimitError < APIError; end

  # ERR_CREDITS_EXHAUSTED (HTTP 429): do NOT retry. Credits come back when the billing period
  # resets or the plan is upgraded. Deliberately not a RateLimitError.
  class CreditsExhaustedError < APIError; end

  # Resource not found (ERR_PRODUCT_NOT_FOUND / ERR_ENDPOINT_NOT_FOUND, HTTP 404)
  class NotFoundError < APIError; end

  # Request validation failed (ERR_INVALID_PARAMS / ERR_IDENTIFIER_REQUIRED, HTTP 400)
  class ValidationError < APIError; end

  # Request timeout
  class TimeoutError < Error; end

  # Network connection error
  class NetworkError < Error; end

  # Configuration error
  class ConfigurationError < Error; end
end