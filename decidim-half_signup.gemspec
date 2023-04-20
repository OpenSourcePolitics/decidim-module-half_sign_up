# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/half_signup/version"

Gem::Specification.new do |s|
  s.version = Decidim::HalfSignup.version
  s.authors = ["Sina Eftekhar"]
  s.email = ["sina.eftekhar@mainiotech.fi"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/decidim/decidim-module-half_signup"
  s.required_ruby_version = ">= 2.7"

  s.name = "decidim-half_signup"
  s.summary = "A decidim half_signup module"
  s.description = "Enbale half-signup option for users."

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "countries", "~> 5.1", ">= 5.1.2"
  s.add_dependency "decidim-core", Decidim::HalfSignup.decidim_version
  s.metadata["rubygems_mfa_required"] = "true"
end
