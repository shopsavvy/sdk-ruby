# -*- encoding: utf-8 -*-
# stub: rubocop-rspec 2.20.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-rspec".freeze
  s.version = "2.20.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/rubocop/rubocop-rspec/blob/master/CHANGELOG.md", "documentation_uri" => "https://docs.rubocop.org/rubocop-rspec/", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Backus".freeze, "Ian MacLeod".freeze, "Nils Gemeinhardt".freeze]
  s.date = "2023-04-18"
  s.description = "    Code style checking for RSpec files.\n    A plugin for the RuboCop code style enforcing & linting tool.\n".freeze
  s.email = ["johncbackus@gmail.com".freeze, "ian@nevir.net".freeze, "git@nilsgemeinhardt.de".freeze]
  s.extra_rdoc_files = ["MIT-LICENSE.md".freeze, "README.md".freeze]
  s.files = ["MIT-LICENSE.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/rubocop/rubocop-rspec".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Code style checking for RSpec files".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubocop>.freeze, ["~> 1.33"])
      s.add_runtime_dependency(%q<rubocop-capybara>.freeze, ["~> 2.17"])
    else
      s.add_dependency(%q<rubocop>.freeze, ["~> 1.33"])
      s.add_dependency(%q<rubocop-capybara>.freeze, ["~> 2.17"])
    end
  else
    s.add_dependency(%q<rubocop>.freeze, ["~> 1.33"])
    s.add_dependency(%q<rubocop-capybara>.freeze, ["~> 2.17"])
  end
end
