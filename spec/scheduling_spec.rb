# frozen_string_literal: true

# The scheduling handlers in refinery's entrypoint-api.ts (`schedule`, `unschedule`)
# read ONLY req.query:
#   PUT    /v1/products/scheduled?ids=<a,b>&schedule=<hourly|daily|weekly>[&retailer=<domain>]
#   DELETE /v1/products/scheduled?ids=<a,b>
# Any request body is ignored, so these examples assert the method, path and query
# string and that no body is sent. Only the HTTP transport is stubbed.
RSpec.describe ShopsavvyDataApi::Client, "scheduling" do
  let(:client) { described_class.new(api_key: "ss_test_fixturekey123") }
  let(:endpoint) { "https://api.shopsavvy.com/v1/products/scheduled" }
  let(:no_body) { ->(req) { req.body.nil? || req.body.empty? } }

  let(:schedule_body) do
    {
      success: true,
      data: [
        { title: "Keurig K-Mini", shopsavvy: "3ONn300xybP3y66ibqc1", barcode: "611247373064", schedule: "daily" },
        { title: "Echo Dot", shopsavvy: "Q2x9Ab", amazon: "B08N5WRWNW", schedule: "daily" }
      ],
      meta: { request_id: "req-1", credits_used: 2, credits_remaining: 998, rate_limit_remaining: 999 }
    }.to_json
  end
  let(:json_headers) { { "Content-Type" => "application/json" } }

  before do
    stub_request(:any, /api\.shopsavvy\.com/).to_return(status: 404, body: "{}", headers: json_headers)
  end

  it "schedules one product with PUT /products/scheduled?ids=&schedule= and no body" do
    stub = stub_request(:put, endpoint)
           .with(query: { ids: "611247373064", schedule: "daily" }, &no_body)
           .to_return(status: 200, body: schedule_body, headers: json_headers)

    result = client.schedule_product_monitoring("611247373064", "daily")

    expect(stub).to have_been_requested.once
    expect(result).to be_success
    expect(result.data.map(&:schedule)).to eq(%w[daily daily])
    expect(result.credits_used).to eq(2)
  end

  it "passes retailer through as a query parameter" do
    stub = stub_request(:put, endpoint)
           .with(query: { ids: "611247373064", schedule: "hourly", retailer: "amazon.com" }, &no_body)
           .to_return(status: 200, body: schedule_body, headers: json_headers)

    client.schedule_product_monitoring("611247373064", "hourly", retailer: "amazon.com")

    expect(stub).to have_been_requested.once
  end

  it "schedules a batch with comma-joined ids" do
    stub = stub_request(:put, endpoint)
           .with(query: { ids: "611247373064,B08N5WRWNW", schedule: "weekly" }, &no_body)
           .to_return(status: 200, body: schedule_body, headers: json_headers)

    client.schedule_product_monitoring_batch(%w[611247373064 B08N5WRWNW], "weekly")

    expect(stub).to have_been_requested.once
  end

  it "schedules a batch with retailer, URL-encoding identifiers in the query string" do
    stub = stub_request(:put, endpoint)
           .with(query: { ids: "611247373064,https://www.bestbuy.com/site/6358476.p?skuId=6358476&ref=NS",
                          schedule: "daily", retailer: "bestbuy.com" }, &no_body)
           .to_return(status: 200, body: schedule_body, headers: json_headers)

    client.schedule_product_monitoring_batch(
      ["611247373064", "https://www.bestbuy.com/site/6358476.p?skuId=6358476&ref=NS"], "daily", retailer: "bestbuy.com"
    )

    # The identifier contains "&ref=NS": had it gone out unencoded, the server (and this
    # exact query match) would see a separate `ref` parameter and a truncated `ids`.
    expect(stub).to have_been_requested.once
  end

  it "unschedules one product with DELETE /products/scheduled?ids= and no body" do
    stub = stub_request(:delete, endpoint)
           .with(query: { ids: "611247373064" }, &no_body)
           .to_return(status: 200, headers: json_headers, body: {
             success: true, message: "Products successfully removed from schedule",
             meta: { request_id: "req-2", credits_used: 0, credits_remaining: 0, rate_limit_remaining: 0 }
           }.to_json)

    result = client.remove_product_from_schedule("611247373064")

    expect(stub).to have_been_requested.once
    expect(result).to be_success
    expect(result.message).to eq("Products successfully removed from schedule")
  end

  it "unschedules a batch with comma-joined ids" do
    stub = stub_request(:delete, endpoint)
           .with(query: { ids: "611247373064,B08N5WRWNW" }, &no_body)
           .to_return(status: 200, headers: json_headers,
                      body: { success: true, message: "Products successfully removed from schedule" }.to_json)

    client.remove_products_from_schedule(%w[611247373064 B08N5WRWNW])

    expect(stub).to have_been_requested.once
  end

  it "never hits the legacy /products/schedule path" do
    stub_request(:put, endpoint).with(query: hash_including({}))
                                .to_return(status: 200, body: schedule_body, headers: json_headers)
    stub_request(:delete, endpoint).with(query: hash_including({}))
                                   .to_return(status: 200, body: { success: true }.to_json, headers: json_headers)

    client.schedule_product_monitoring("611247373064", "daily")
    client.remove_product_from_schedule("611247373064")

    expect(a_request(:any, %r{/v1/products/schedule(\?|\z)})).not_to have_been_made
  end
end
