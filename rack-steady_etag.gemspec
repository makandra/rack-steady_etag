# frozen_string_literal: true

require_relative "lib/rack/steady_etag/version"

Gem::Specification.new do |spec|
  spec.name = "rack-steady_etag"
  spec.version = Rack::SteadyEtag::VERSION
  spec.authors = ["Henning Koch"]
  spec.email = ["henning.koch@makandra.de"]

  spec.summary = "Rack Middleware that produces the same ETag for responses that only differ in CSRF tokens or CSP nonce"
  spec.description = spec.summary
  spec.homepage = "https://github.com/makandra/rack-steady_etag"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "rack"
  spec.add_dependency 'activesupport', '>= 3.2'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
