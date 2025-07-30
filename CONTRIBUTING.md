# Contributing to ShopSavvy Ruby SDK

Thank you for your interest in contributing to the ShopSavvy Ruby SDK! This document provides guidelines for contributing to this open-source project.

## Development Setup

### Prerequisites

- Ruby 2.7.0 or higher
- Bundler for dependency management
- A ShopSavvy Data API key (get one at [https://shopsavvy.com/data](https://shopsavvy.com/data))

### Setup Steps

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/ruby-sdk
   cd ruby-sdk
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up environment**
   ```bash
   export SHOPSAVVY_API_KEY="your_api_key_here"
   ```

4. **Run tests to verify setup**
   ```bash
   bundle exec rspec
   ```

## Development Workflow

### Project Structure

```
lib/
├── shopsavvy_data_api.rb         # Main module and factory methods
├── shopsavvy_data_api/
│   ├── version.rb                # Version constant
│   ├── errors.rb                 # Exception classes
│   ├── models.rb                 # Data models and configuration
│   └── client.rb                 # Main API client

spec/
├── spec_helper.rb                # RSpec configuration
├── shopsavvy_data_api_spec.rb    # Main module tests
├── client_spec.rb                # Client tests
├── models_spec.rb                # Model tests
├── fixtures/                     # Test data fixtures
└── support/                      # Test support files
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/client_spec.rb

# Run with coverage report
bundle exec rspec --format documentation

# Run tests with verbose output
bundle exec rspec --format documentation --color

# Run integration tests (requires API key)
SHOPSAVVY_API_KEY=your_key bundle exec rspec --tag integration
```

### Code Quality

```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix RuboCop issues
bundle exec rubocop -A

# Generate documentation
bundle exec yard doc

# View documentation
bundle exec yard server
```

## Code Guidelines

### Ruby Standards

- Follow the [Ruby Style Guide](https://rubystyle.guide/)
- Use RuboCop for consistent style enforcement
- Write comprehensive documentation using YARD
- Maintain Ruby 2.7+ compatibility
- Use semantic versioning for releases

### Code Style

- Use 2 spaces for indentation
- Use double quotes for strings with interpolation, single quotes otherwise
- Use meaningful variable and method names
- Keep methods focused and small (under 10 lines when possible)
- Use descriptive commit messages

### Documentation Standards

Use YARD for all public methods:

```ruby
# Look up product details by identifier
#
# @param identifier [String] Product identifier (barcode, ASIN, URL, model number, 
#   or ShopSavvy product ID)
# @param format [String, nil] Response format ('json' or 'csv')
# @return [APIResponse<ProductDetails>] Product details
# @raise [NotFoundError] If product is not found
# @raise [ValidationError] If identifier format is invalid
#
# @example
#   product = client.get_product_details("012345678901")
#   puts product.data.name
def get_product_details(identifier, format: nil)
  # implementation
end
```

### Error Handling

- Use custom exception classes from `errors.rb`
- Provide meaningful error messages with context
- Include HTTP status codes and response data when available
- Handle network timeouts and connection failures gracefully

```ruby
begin
  response = @connection.get(path, params)
rescue Faraday::TimeoutError => e
  raise TimeoutError, "Request timeout after #{config.timeout} seconds: #{e.message}"
rescue Faraday::ConnectionFailed => e
  raise NetworkError, "Network connection failed: #{e.message}"
end
```

## Adding New Features

### Adding New API Methods

1. **Define the method in `Client` class**
   ```ruby
   def new_api_method(param1, param2 = nil)
     params = { param1: param1 }
     params[:param2] = param2 if param2
     
     response = make_request(:get, "/new/endpoint", params: params)
     APIResponse.new(response, data_class: ResponseModel)
   end
   ```

2. **Add comprehensive documentation**
   - Parameter descriptions
   - Return value description
   - Possible exceptions
   - Usage examples

3. **Create response model if needed**
   ```ruby
   class NewResponseModel
     attr_reader :field1, :field2
     
     def initialize(data)
       @field1 = data["field1"]
       @field2 = data["field2"]
     end
     
     def to_h
       { field1: field1, field2: field2 }
     end
   end
   ```

4. **Write comprehensive tests**
   - Unit tests with mocked responses
   - Integration tests with real API
   - Error condition tests

5. **Update documentation**
   - Add examples to README
   - Update YARD documentation

### Adding New Models

1. **Define the model class**
   ```ruby
   class NewModel
     attr_reader :field1, :field2
     
     def initialize(data)
       @field1 = data["field1"]
       @field2 = data["field2"]&.to_f
     end
     
     def to_h
       { field1: field1, field2: field2 }
     end
     
     # Add convenience methods
     def active?
       field1 == "active"
     end
   end
   ```

2. **Add validation if needed**
3. **Write tests for the model**
4. **Update exports in main module**

## Testing

### Unit Tests

Write comprehensive unit tests using RSpec:

```ruby
RSpec.describe ShopsavvyDataApi::Client do
  let(:client) { described_class.new(api_key: "ss_test_123") }
  
  describe "#get_product_details" do
    context "when product exists" do
      before do
        stub_request(:get, %r{/products/details})
          .to_return(
            status: 200,
            body: {
              success: true,
              data: { product_id: "123", name: "Test Product" }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end
      
      it "returns product details" do
        result = client.get_product_details("123")
        
        expect(result.success?).to be true
        expect(result.data.name).to eq "Test Product"
      end
    end
    
    context "when product not found" do
      before do
        stub_request(:get, %r{/products/details})
          .to_return(status: 404, body: { error: "Not found" }.to_json)
      end
      
      it "raises NotFoundError" do
        expect { client.get_product_details("invalid") }
          .to raise_error(ShopsavvyDataApi::NotFoundError)
      end
    end
  end
end
```

### Integration Tests

Test against real API when possible:

```ruby
RSpec.describe ShopsavvyDataApi::Client, :integration do
  let(:api_key) { ENV["SHOPSAVVY_API_KEY"] }
  let(:client) { described_class.new(api_key: api_key) }
  
  before do
    skip "SHOPSAVVY_API_KEY not set" unless api_key
  end
  
  it "fetches real product data" do
    result = client.get_product_details("012345678901")
    
    expect(result.success?).to be true
    expect(result.data.product_id).to be_present
  end
end
```

### Test Configuration

Configure RSpec in `spec_helper.rb`:

```ruby
require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "bundler/setup"
require "shopsavvy_data_api"
require "webmock/rspec"
require "vcr"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
  
  config.order = :random
  Kernel.srand config.seed
end

# VCR configuration for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<API_KEY>") { ENV["SHOPSAVVY_API_KEY"] }
end
```

## Documentation

### README Updates

- Keep examples current and working
- Update installation instructions for new features
- Add new methods to API reference section
- Ensure all links work correctly

### YARD Documentation

Write comprehensive YARD documentation:

```ruby
# @!group Product Methods

# Look up product details by identifier
#
# This method allows you to retrieve detailed information about a product
# using various types of identifiers including barcodes, ASINs, URLs, and more.
#
# @param identifier [String] Product identifier. Supported formats:
#   - Barcodes (UPC, EAN, ISBN, GTIN)
#   - Amazon ASINs (e.g., "B08N5WRWNW")
#   - Product URLs from any retailer
#   - Model numbers or MPNs
#   - ShopSavvy product IDs
# @param format [String, nil] Response format. Options:
#   - "json" (default) - Returns structured data
#   - "csv" - Returns CSV formatted data
#
# @return [APIResponse<ProductDetails>] Response containing product details
#
# @raise [NotFoundError] When the product cannot be found
# @raise [ValidationError] When the identifier format is invalid
# @raise [AuthenticationError] When the API key is invalid
# @raise [RateLimitError] When rate limits are exceeded
#
# @example Basic product lookup
#   product = client.get_product_details("012345678901")
#   puts "Product: #{product.data.name}"
#   puts "Brand: #{product.data.brand}"
#
# @example Lookup by Amazon ASIN
#   product = client.get_product_details("B08N5WRWNW")
#   puts "ASIN: #{product.data.asin}"
#
# @example CSV format response
#   csv_data = client.get_product_details("012345678901", format: "csv")
#   puts csv_data.data
#
# @since 1.0.0
def get_product_details(identifier, format: nil)
  # implementation
end

# @!endgroup
```

## Submitting Changes

### Pull Request Process

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Add tests for new functionality**
5. **Update documentation**
6. **Run all quality checks**
   ```bash
   bundle exec rspec
   bundle exec rubocop
   bundle exec yard doc
   ```
7. **Submit a pull request**

### Pull Request Guidelines

- **Clear title**: Describe what the PR does in the title
- **Detailed description**: Explain the changes and why they're needed
- **Breaking changes**: Clearly mark any breaking changes
- **Test coverage**: Ensure all new code is tested
- **Documentation**: Update relevant documentation

### Commit Message Format

Use conventional commit messages:

```
feat: add support for batch product lookups
fix: handle timeout errors properly  
docs: update README with new examples
test: add integration tests for price history
refactor: improve error handling consistency
style: fix RuboCop violations
```

## Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes to public API
- **MINOR**: New features (backwards compatible)  
- **PATCH**: Bug fixes (backwards compatible)

### Pre-release Checklist

- [ ] All tests pass
- [ ] RuboCop passes with no violations
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] Version bumped in `version.rb`
- [ ] Gemspec updated if needed

### Release Steps

1. Update version in `lib/shopsavvy_data_api/version.rb`
2. Update `CHANGELOG.md` with new version
3. Update README if needed
4. Commit changes: `git commit -m "chore: bump version to v1.x.x"`
5. Create git tag: `git tag v1.x.x`
6. Push changes: `git push origin main --tags`
7. Build gem: `gem build shopsavvy_data_api.gemspec`
8. Publish to RubyGems: `gem push shopsavvy_data_api-1.x.x.gem`
9. Create GitHub release with changelog

## Code Quality Standards

### RuboCop Configuration

Ensure your `.rubocop.yml` follows project standards:

```yaml
require:
  - rubocop-rspec

AllCops:
  TargetRubyVersion: 2.7
  NewCops: enable
  Exclude:
    - 'bin/**/*'
    - 'vendor/**/*'

Style/Documentation:
  Enabled: false

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - '*.gemspec'

Layout/LineLength:
  Max: 100
  Exclude:
    - 'spec/**/*'
```

### Test Coverage

Maintain high test coverage:

```bash
# Check coverage report
bundle exec rspec
open coverage/index.html
```

Target: >90% test coverage

### Performance

- Use efficient HTTP client (Faraday with connection reuse)
- Implement proper retry logic with exponential backoff
- Cache configuration objects
- Avoid unnecessary object allocation in hot paths

## Support

- **Issues**: Report bugs and request features via GitHub Issues
- **Discussions**: Use GitHub Discussions for questions and ideas  
- **Email**: Contact us at [business@shopsavvy.com](mailto:business@shopsavvy.com)

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make the ShopSavvy Ruby SDK better! 🛍️💎