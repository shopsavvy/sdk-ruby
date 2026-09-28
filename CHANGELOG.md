# Changelog

All notable changes to the `shopsavvy-sdk` gem are recorded here.

## 1.4.0

### Changed (breaking for `get_price_history` callers)
- `get_price_history` now returns `APIResponse<Array<ProductWithOfferHistory>>`: one entry
  per product found (every product field), each with `offers`, each offer an
  `OfferWithHistory` carrying its `history` points (newest first). It previously parsed each
  product as an offer, so every offer and every history point in the response was lost.
  Iterate `result.data.each { |product| product.offers.each { |offer| offer.history } }`.

### Fixed
- `Offer#url` and `Offer#to_h` raised `NameError` (a bare `URL` resolves as a constant).
- `PriceHistoryEntry#price` keeps a missing price as `nil` instead of `0.0`;
  `OfferWithHistory#min_price` / `#max_price` / `#average_price` ignore `nil` prices.
- The published gem no longer includes the previously-tracked `vendor/bundle` directory.

### Added
- RSpec suite (`bundle exec rspec`) covering price history against the real wire shape.

## 1.3.0 (unreleased, folded into 1.4.0)
- `get_price_history` sends `start` / `end` (it sent `start_date` / `end_date`, which the
  REST endpoint rejected).
- History points are read from `timestamp` (not `date`) and expose `currency`
  (`nil` when the archived point has none — never assume USD).
- `OfferWithHistory` reads `history` instead of a `price_history` key the API never sent.

## 1.2.0
- `score` documented as a 0-1 scale with a free-form `aspects` hash; `update_webhook`.

## 1.1.0
- Deals, reviews, batch lookup and webhook endpoints; expanded product fields.
