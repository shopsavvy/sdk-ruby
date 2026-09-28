# frozen_string_literal: true

# Drives a response of the exact shape GET /v1/products/offers/history returns
# (refinery entrypoint-api.ts `offerHistory`: one entry per PRODUCT, each with its
# offers, each offer with its `history` points) through the real client. Only the
# HTTP transport is stubbed.
RSpec.describe ShopsavvyDataApi::Client, "#get_price_history" do
  let(:client) { described_class.new(api_key: "ss_test_fixturekey123") }
  let(:endpoint) { "https://api.shopsavvy.com/v1/products/offers/history" }

  let!(:request_stub) do
    stub_request(:get, endpoint)
      .with(query: { ids: "611247373064,611247369449", start: "2022-11-20", end: "2022-11-27" })
      .to_return(
        status: 200,
        body: fixture_json("price_history_response.json"),
        headers: { "Content-Type" => "application/json" }
      )
  end

  subject(:result) do
    client.get_price_history("611247373064,611247369449", "2022-11-20", "2022-11-27")
  end

  it "sends start/end (never start_date/end_date) and the User-Agent version" do
    result
    expect(
      a_request(:get, endpoint)
        .with(
          query: { ids: "611247373064,611247369449", start: "2022-11-20", end: "2022-11-27" },
          headers: { "User-Agent" => "ShopSavvy-Ruby-SDK/#{ShopsavvyDataApi::VERSION}" }
        )
    ).to have_been_made.once
  end

  it "passes the optional retailer filter through" do
    stub = stub_request(:get, endpoint)
           .with(query: { ids: "611247373064", start: "2022-11-20", end: "2022-11-27", retailer: "amazon.com" })
           .to_return(status: 200, body: fixture_json("price_history_response.json"),
                      headers: { "Content-Type" => "application/json" })
    client.get_price_history("611247373064", "2022-11-20", "2022-11-27", retailer: "amazon.com")
    expect(stub).to have_been_requested.once
  end

  it "parses the envelope and meta" do
    expect(result).to be_success
    expect(result.credits_used).to eq(14)
    expect(result.credits_remaining).to eq(986)
    expect(result.meta.rate_limit_remaining).to eq(999)
  end

  it "returns one ProductWithOfferHistory per product with product fields intact" do
    expect(result.data.length).to eq(2)
    expect(result.data).to all(be_a(ShopsavvyDataApi::ProductWithOfferHistory))

    keurig = result.data[0]
    expect(keurig.title).to eq("Keurig K-Mini Single Serve Coffee Maker, Black")
    expect(keurig.shopsavvy).to eq("3ONn300xybP3y66ibqc1")
    expect(keurig.barcode).to eq("611247373064")
    expect(keurig.amazon).to eq("B07G14HTBZ")
    expect(keurig.brand).to eq("Keurig")
    expect(keurig.title_short).to eq("Keurig K-Mini")
    expect(keurig.rating).to eq({ "value" => 4.6, "count" => 51_234 })
    expect(keurig.images.length).to eq(1)

    elite = result.data[1]
    expect(elite.shopsavvy).to eq("DrKWneG0MpFlZpwZXNYa")
    expect(elite.category).to be_nil
    expect(elite.amazon).to be_nil
    expect(elite.mpn).to be_nil
    expect(elite.images).to eq([])
  end

  it "parses every offer with all offer fields and its history" do
    offers = result.data[0].offers
    expect(offers.length).to eq(2)
    expect(offers).to all(be_a(ShopsavvyDataApi::OfferWithHistory))

    amazon = offers[0]
    expect(amazon.id).to eq("0IUouCFtZEhxeOablTPl")
    expect(amazon.retailer).to eq("Amazon")
    expect(amazon.price).to eq(74.96)
    expect(amazon.currency).to eq("USD")
    expect(amazon.availability).to eq("in")
    expect(amazon.condition).to eq("new")
    expect(amazon.seller).to eq("ACME Deals")
    expect(amazon.URL).to eq("https://www.amazon.com/dp/B07G14HTBZ?m=A1GKQADQC2VI6E")
    expect(amazon.timestamp).to eq("2022-11-27T22:36:33.236Z")
    expect(amazon.url).to eq(amazon.URL) # deprecated alias

    best_buy = offers[1]
    expect(best_buy.retailer).to eq("Best Buy")
    expect(best_buy.availability).to be_nil # omitted on the wire when unknown
    expect(best_buy.seller).to be_nil       # explicit JSON null
    expect(best_buy.history.length).to eq(2)
  end

  it "parses history points (newest first) including currency and a missing availability" do
    history = result.data[0].offers[0].history
    expect(history.length).to eq(3)
    expect(history).to all(be_a(ShopsavvyDataApi::PriceHistoryEntry))

    expect(history.map(&:timestamp)).to eq([
      "2022-11-27T22:36:33.236Z", "2022-11-24T10:00:00.000Z", "2022-11-21T08:15:00.000Z"
    ])
    expect(history.map(&:price)).to eq([74.96, 70.99, 79.99])
    expect(history.map(&:availability)).to eq(["in", "out", nil])
    expect(history[0].currency).to eq("USD")
    expect(history[2].currency).to be_nil # null currency is NOT coerced to USD
  end

  it "computes price aggregates over the parsed history" do
    amazon = result.data[0].offers[0]
    expect(amazon.min_price).to eq(70.99)
    expect(amazon.max_price).to eq(79.99)
    expect(amazon.average_price).to be_within(0.0001).of((74.96 + 70.99 + 79.99) / 3)
  end

  it "keeps an offer with an empty history (eBay listings carry none)" do
    ebay = result.data[1].offers[0]
    expect(ebay.retailer).to eq("eBay")
    expect(ebay.condition).to eq("used")
    expect(ebay.history).to eq([])
    expect(ebay.min_price).to be_nil
    expect(ebay.average_price).to be_nil
  end

  it "round-trips through to_h" do
    h = result.data[0].to_h
    expect(h[:shopsavvy]).to eq("3ONn300xybP3y66ibqc1")
    expect(h[:offers][0][:history][1]).to eq(
      timestamp: "2022-11-24T10:00:00.000Z", price: 70.99, currency: "USD", availability: "out"
    )
  end
end
