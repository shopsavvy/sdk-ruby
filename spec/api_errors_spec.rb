# frozen_string_literal: true

require "spec_helper"
require "socket"

# A real HTTP server on localhost answers; the real client and real Faraday adapter talk to
# it. WebMock is switched off for this file only (spec_helper blocks all network by default).
RSpec.describe "typed API errors" do
  def error_body(code, message, request_id = "req_123")
    {
      success: false,
      error: message,
      error_detail: {
        code: code,
        message: message,
        action: "Do the thing",
        docs_url: "https://shopsavvy.com/data/documentation/errors##{code.downcase}"
      },
      meta: { request_id: request_id }
    }
  end

  before(:all) do
    WebMock.allow_net_connect!
    @reply = { status: 500, headers: {}, body: "{}", type: "application/json" }
    @tcp = TCPServer.new("127.0.0.1", 0)
    @port = @tcp.addr[1]
    @thread = Thread.new do
      loop do
        socket = @tcp.accept
        while (line = socket.gets) && line != "\r\n"; end # drain request head
        payload = @reply[:body]
        head = "HTTP/1.1 #{@reply[:status]} X\r\nContent-Type: #{@reply[:type]}\r\n"
        @reply[:headers].each { |k, v| head += "#{k}: #{v}\r\n" }
        socket.write("#{head}Content-Length: #{payload.bytesize}\r\nConnection: close\r\n\r\n#{payload}")
        socket.close
      end
    end
  end

  after(:all) do
    @thread.kill
    @tcp.close
    WebMock.disable_net_connect!
  end

  def reply(status, body, headers = {}, type: "application/json")
    @reply[:type] = type
    @reply[:status] = status
    @reply[:headers] = headers
    @reply[:body] = body.is_a?(String) ? body : JSON.generate(body)
  end

  def raised
    client = ShopsavvyDataApi.new(api_key: "ss_test_fixturekey123", base_url: "http://127.0.0.1:#{@port}/v1")
    client.get_product_details("611247373064")
    raise "expected the call to raise"
  rescue ShopsavvyDataApi::APIError => e
    e
  end

  it "ERR_RATE_LIMIT is a RateLimitError carrying detail and Retry-After" do
    reply(429, error_body("ERR_RATE_LIMIT", "Rate limit exceeded"), { "Retry-After" => "7" })
    e = raised
    expect(e).to be_a(ShopsavvyDataApi::RateLimitError)
    expect(e).not_to be_a(ShopsavvyDataApi::CreditsExhaustedError)
    expect(e.message).to eq("Rate limit exceeded")
    expect(e.status_code).to eq(429)
    expect(e.code).to eq("ERR_RATE_LIMIT")
    expect(e.action).to eq("Do the thing")
    expect(e.docs_url).to eq("https://shopsavvy.com/data/documentation/errors#err_rate_limit")
    expect(e.request_id).to eq("req_123")
    expect(e.retry_after_seconds).to eq(7)
  end

  it "ERR_CREDITS_EXHAUSTED is its own type and not a RateLimitError" do
    reply(429, error_body("ERR_CREDITS_EXHAUSTED", "Credits exhausted"))
    e = raised
    expect(e).to be_a(ShopsavvyDataApi::CreditsExhaustedError)
    expect(e).to be_a(ShopsavvyDataApi::APIError)
    expect(e).not_to be_a(ShopsavvyDataApi::RateLimitError)
    expect(e.code).to eq("ERR_CREDITS_EXHAUSTED")
    expect(e.retry_after_seconds).to be_nil
  end

  it "a 429 without error_detail (older server) stays a RateLimitError with nil code" do
    reply(429, { success: false, error: "Too many requests" }, { "Retry-After" => "3" })
    e = raised
    expect(e).to be_a(ShopsavvyDataApi::RateLimitError)
    expect(e.message).to eq("Too many requests")
    expect([e.code, e.action, e.docs_url, e.request_id]).to all(be_nil)
    expect(e.retry_after_seconds).to eq(3)
  end

  it "maps 401, 404 and 400 to their classes" do
    reply(401, error_body("ERR_AUTH_INVALID", "Invalid API key"))
    expect(raised).to be_a(ShopsavvyDataApi::AuthenticationError)
    reply(404, error_body("ERR_PRODUCT_NOT_FOUND", "Product not found"))
    expect(raised).to be_a(ShopsavvyDataApi::NotFoundError)
    reply(400, error_body("ERR_INVALID_PARAMS", "Bad ids"))
    expect(raised).to be_a(ShopsavvyDataApi::ValidationError)
  end

  it "other codes are a plain APIError carrying the detail" do
    reply(403, error_body("ERR_SUBSCRIPTION_REQUIRED", "Subscription required"))
    e = raised
    expect(e.class).to eq(ShopsavvyDataApi::APIError)
    expect(e.code).to eq("ERR_SUBSCRIPTION_REQUIRED")
    expect(e.status_code).to eq(403)
  end

  it "a non-JSON error body still raises a typed error" do
    reply(502, "<html>bad gateway</html>", {}, type: "text/html")
    e = raised
    expect(e.class).to eq(ShopsavvyDataApi::APIError)
    expect(e.status_code).to eq(502)
    expect(e.code).to be_nil
  end

  # Costs nothing: a well-formed nonexistent key is rejected before any credit is touched.
  it "live: a bogus ss_live_ key gets ERR_AUTH_REVOKED with code and docs_url" do
    client = ShopsavvyDataApi.new(api_key: "ss_live_#{'a' * 32}")
    expect { client.get_product_details("611247373064") }.to raise_error(ShopsavvyDataApi::AuthenticationError) do |e|
      expect(e.code).to eq("ERR_AUTH_REVOKED")
      expect(e.docs_url).to start_with("https://shopsavvy.com/data/documentation/errors")
      expect(e.status_code).to eq(401)
    end
  end
end
