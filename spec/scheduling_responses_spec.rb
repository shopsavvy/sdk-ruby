# frozen_string_literal: true

# Response shapes of the three scheduling handlers in refinery's entrypoint-api.ts:
#   PUT    /products/scheduled -> { success, data: [{ ...publicProduct, schedule, retailer? }], meta }
#   DELETE /products/scheduled -> { success, message, meta }             (no data)
#   GET    /products/scheduled -> { success, data: [{ ...publicProduct, schedule?, retailer? }], meta }
# The fixtures are those exact shapes; only the HTTP transport is stubbed, so the real
# client + model parsing runs.
RSpec.describe ShopsavvyDataApi::Client, "scheduling responses" do
  let(:client) { described_class.new(api_key: "ss_test_fixturekey123") }
  let(:endpoint) { "https://api.shopsavvy.com/v1/products/scheduled" }
  let(:json_headers) { { "Content-Type" => "application/json" } }

  it "parses PUT /products/scheduled into ScheduledProduct entries carrying every product field" do
    stub_request(:put, endpoint)
      .with(query: { ids: "611247373064,B08N5WRWNW", schedule: "hourly", retailer: "amazon.com" })
      .to_return(status: 200, body: fixture_json("schedule_response.json"), headers: json_headers)

    result = client.schedule_product_monitoring_batch(%w[611247373064 B08N5WRWNW], "hourly", retailer: "amazon.com")

    expect(result).to be_success
    expect(result.data.length).to eq(2)
    expect(result.data).to all(be_a(ShopsavvyDataApi::ScheduledProduct))
    expect(result.data).to all(be_a(ShopsavvyDataApi::ProductDetails))

    keurig = result.data[0]
    expect(keurig.title).to eq("Keurig K-Mini Single Serve Coffee Maker, Black")
    expect(keurig.shopsavvy).to eq("3ONn300xybP3y66ibqc1")
    expect(keurig.barcode).to eq("611247373064")
    expect(keurig.amazon).to eq("B07GV2S1GS")
    expect(keurig.model).to eq("K-Mini")
    expect(keurig.mpn).to eq("5000200237")
    expect(keurig.brand).to eq("Keurig")
    expect(keurig.images).to eq(["https://images.example/keurig-1.jpg", "https://images.example/keurig-2.jpg"])
    expect(keurig.title_short).to eq("Keurig K-Mini")
    expect(keurig.rating).to eq({ "value" => 4.5, "count" => 81_234 })
    expect(keurig.schedule).to eq("hourly")
    expect(keurig.frequency).to eq("hourly")
    expect(keurig).to be_hourly
    expect(keurig).not_to be_daily
    expect(keurig.retailer).to eq("amazon.com")
    expect(keurig.to_h).to include(shopsavvy: "3ONn300xybP3y66ibqc1", schedule: "hourly", retailer: "amazon.com")

    echo = result.data[1]
    expect(echo.category).to be_nil
    expect(echo.barcode).to be_nil
    expect(echo.images).to eq([])

    expect(result.meta.credits_used).to eq(2)
    expect(result.meta.credits_remaining).to eq(998)
    expect(result.meta.rate_limit_remaining).to eq(59)
  end

  it "parses DELETE /products/scheduled as success + message + meta with no data" do
    stub_request(:delete, endpoint)
      .with(query: { ids: "611247373064" })
      .to_return(status: 200, body: fixture_json("unschedule_response.json"), headers: json_headers)

    result = client.remove_product_from_schedule("611247373064")

    expect(result).to be_success
    expect(result.message).to eq("Products successfully removed from schedule")
    expect(result.data).to be_nil
    expect(result.meta.credits_used).to eq(0)
    expect(result.meta.credits_remaining).to eq(0)
    expect(result.meta.rate_limit_remaining).to eq(0)
  end

  it "parses GET /products/scheduled, with schedule and retailer nil when the server omits them" do
    stub_request(:get, endpoint)
      .to_return(status: 200, body: fixture_json("scheduled_list_response.json"), headers: json_headers)

    result = client.get_scheduled_products

    expect(result).to be_success
    expect(result.data.map(&:class).uniq).to eq([ShopsavvyDataApi::ScheduledProduct])
    expect(result.data.map(&:shopsavvy)).to eq(%w[3ONn300xybP3y66ibqc1 Q2x9AbCdEf Zz81Sony])
    expect(result.data.map(&:schedule)).to eq(["daily", "weekly", nil])
    expect(result.data.map(&:retailer)).to eq(["bestbuy.com", nil, nil])

    keurig, echo, sony = result.data
    expect(keurig).to be_daily
    expect(keurig.title).to eq("Keurig K-Mini Single Serve Coffee Maker, Black")
    expect(keurig.model).to eq("K-Mini")
    expect(echo).to be_weekly
    expect(echo.amazon).to eq("B08N5WRWNW")
    expect(sony).not_to be_hourly
    expect(sony).not_to be_daily
    expect(sony).not_to be_weekly
    expect(sony.barcode).to eq("027242923232")
    expect(result.meta.credits_used).to eq(0)
  end
end
