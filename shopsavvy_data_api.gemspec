# frozen_string_literal: true

require_relative "lib/shopsavvy_data_api/version"

Gem::Specification.new do |spec|
  spec.name = "shopsavvy-sdk"
  spec.version = ShopsavvyDataApi::VERSION
  spec.authors = ["ShopSavvy by Monolith Technologies, Inc."]
  spec.email = ["business@shopsavvy.com"]

  spec.summary = "Official Ruby SDK for ShopSavvy Data API"
  spec.description = "Access product data, pricing, and price history across thousands of retailers and millions of products with the ShopSavvy Data API."
  spec.homepage = "https://shopsavvy.com/data"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shopsavvy/sdk-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/shopsavvy/sdk-ruby/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://shopsavvy.com/data/documentation"
  spec.metadata["bug_tracker_uri"] = "https://github.com/shopsavvy/sdk-ruby/issues"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rspec", "~> 2.0"
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "vcr", "~> 6.1"
  spec.add_development_dependency "yard", "~> 0.9"
end