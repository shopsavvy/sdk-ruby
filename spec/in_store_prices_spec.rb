# frozen_string_literal: true

# GET /products/offers carries, per product, an in_store_prices array: shelf prices read from
# shoppers' scanned receipts, labeled source "user-collected".
RSpec.describe ShopsavvyDataApi::Client, "in-store prices" do
  let(:client) { described_class.new(api_key: "ss_test_fixturekey123") }
  let(:json_headers) { { "Content-Type" => "application/json" } }
  let(:body) { File.read(File.join(__dir__, "fixtures", "offers_in_store_response.json")) }

  it "parses user-collected in-store prices next to the offers" do
    stub_request(:get, "https://api.shopsavvy.com/v1/products/offers")
      .with(query: { ids: "011110838360" })
      .to_return(status: 200, body: body, headers: json_headers)

    product = client.get_current_offers("011110838360").data.first
    in_store = product.in_store_prices.first
    expect(in_store.source).to eq("user-collected")
    expect(in_store.retailer).to eq("Kroger")
    expect(in_store.address).to eq("1014 Vine St, Cincinnati, OH 45202, USA")
    expect(in_store.latitude).to eq(39.1086)
    expect(in_store.price).to eq(3.49)
    expect(in_store.observed_on).to eq("2026-11-07")
    expect(product.offers.first.retailer).to eq("Walmart")
  end

  it "is empty when the server sends none" do
    parsed = JSON.parse(body)
    parsed["data"].first.delete("in_store_prices")
    stub_request(:get, "https://api.shopsavvy.com/v1/products/offers")
      .with(query: { ids: "011110838360" })
      .to_return(status: 200, body: parsed.to_json, headers: json_headers)

    expect(client.get_current_offers("011110838360").data.first.in_store_prices).to eq([])
  end
end
