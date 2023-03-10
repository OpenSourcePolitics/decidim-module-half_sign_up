# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Webpacker.register_path("#{base_path}/app/packs")
Decidim::Webpacker.register_entrypoints(
  decidim_half_signup: "#{base_path}/app/packs/entrypoints/decidim_half_signup.js",
  decidim_select_country: "#{base_path}/app/packs/entrypoints/decidim_select_country.js",
  decidim_verification: "#{base_path}/app/packs/entrypoints/decidim_verification.js"
)
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/half_signup/half_signup")
