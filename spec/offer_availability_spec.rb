# frozen_string_literal: true

# publicOfferForOfferDoc emits the canonical availability tokens ("in", "out", "limited",
# "pre-order", "coming-soon", "discontinued") and omits the field when it is "unknown".
# The predicates used to compare against "in_stock"/"out_of_stock"/"limited_stock".
RSpec.describe ShopsavvyDataApi::Client, "offer availability" do
  let(:client) { described_class.new(api_key: "ss_test_fixturekey123") }
  let(:json_headers) { { "Content-Type" => "application/json" } }

  let(:offers_body) do
    offer = lambda do |id, availability|
      o = { id: id, condition: "new", retailer: "Best Buy", currency: "USD", price: 49.99,
            URL: "https://www.bestbuy.com/site/#{id}.p", timestamp: "2026-09-20T12:00:00.000Z", history: [] }
      o[:availability] = availability if availability
      o
    end
    {
      success: true,
      data: [{
        title: "Keurig K-Mini", shopsavvy: "3ONn300xybP3y66ibqc1", barcode: "611247373064", images: [],
        offers: [
          offer.call("o-in", "in"), offer.call("o-out", "out"), offer.call("o-limited", "limited"),
          offer.call("o-pre", "pre-order"), offer.call("o-soon", "coming-soon"),
          offer.call("o-disc", "discontinued"), offer.call("o-unknown", nil)
        ]
      }],
      meta: { request_id: "req-offers", credits_used: 3, credits_remaining: 997, rate_limit_remaining: 59 }
    }.to_json
  end

  it "maps the API's availability tokens onto the predicates" do
    stub_request(:get, "https://api.shopsavvy.com/v1/products/offers")
      .with(query: { ids: "611247373064" })
      .to_return(status: 200, body: offers_body, headers: json_headers)

    result = client.get_current_offers("611247373064")
    offers = result.data.first.offers.to_h { |o| [o.id, o] }

    expect(offers["o-in"]).to be_in_stock
    expect(offers["o-in"]).not_to be_out_of_stock
    expect(offers["o-out"]).to be_out_of_stock
    expect(offers["o-out"]).not_to be_in_stock
    expect(offers["o-limited"]).to be_limited_stock
    expect(offers["o-limited"]).not_to be_in_stock
    expect(offers["o-pre"]).to be_pre_order
    expect(offers["o-soon"]).to be_coming_soon
    expect(offers["o-disc"]).to be_discontinued
    expect(offers["o-unknown"].availability).to be_nil
    expect(offers["o-unknown"]).not_to be_in_stock
    expect(offers["o-unknown"]).not_to be_out_of_stock
    expect(offers.values.count(&:in_stock?)).to eq(1)
  end
end
