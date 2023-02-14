# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module HalfSignup
    # This is the engine that runs on the public interface of half_signup.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::HalfSignup

      initializer "HalfSignup.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
