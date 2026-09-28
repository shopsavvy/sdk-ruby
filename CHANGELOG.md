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
- Scheduling actually reaches the API. `schedule_product_monitoring`,
  `schedule_product_monitoring_batch`, `remove_product_from_schedule` and
  `remove_products_from_schedule` sent a JSON body (`identifier(s)`, `frequency`, `retailer`)
  via POST/DELETE to `/products/schedule`; the server reads only the query string, so every
  call failed with a missing-`ids` error. They now send
  `PUT /products/scheduled?ids=a,b&schedule=daily[&retailer=amazon.com]` and
  `DELETE /products/scheduled?ids=a,b` with no body.
- Scheduling responses are typed to what the server sends. `schedule_product_monitoring`,
  `schedule_product_monitoring_batch` and `get_scheduled_products` return
  `APIResponse<Array<ScheduledProduct>>`, and `ScheduledProduct` is now a `ProductDetails`
  (every product field) plus `schedule` and `retailer`. It previously read `product_id`,
  `identifier`, `frequency`, `created_at` and `last_refreshed` — keys the API never sends —
  so every field was nil; `frequency` remains as a deprecated alias of `schedule`. On the
  list, `schedule` is nil for an interval with no Data API label and `retailer` is nil when
  the product is watched at every retailer. `remove_product(s)_from_schedule` return
  `success?`, `message` and `meta`; the server sends no `data`.
- `Offer#in_stock?`, `#out_of_stock?` and `#limited_stock?` compared `availability` against
  `"in_stock"` / `"out_of_stock"` / `"limited_stock"`, which the API never sends, so they
  were always false. They now match the API's tokens (`"in"`, `"out"`, `"limited"`), and
  `#pre_order?`, `#coming_soon?` and `#discontinued?` were added. README availability
  examples use the predicates.
- Internal requests always put `params` in the query string (Faraday's `put`/`post` helpers
  treat their second argument as the body).
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
