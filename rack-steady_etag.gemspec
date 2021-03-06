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
  spec.metadata["bug_tracker_uri"] = spec.homepage + "/issues"
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/master/CHANGELOG.md"
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

  # Rack 1.4.7 is the last version compatible with Rails 3.2.
  #
  # I expect Rack 3 to have a new ETag middleware to no longer buffer
  # streaming responses: https://github.com/rack/rack/issues/1619
  # Once Rack 3 is out we should release a new version of this gem.
  spec.add_dependency "rack", '>=1.4.7', '<3'
end
