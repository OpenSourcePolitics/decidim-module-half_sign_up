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

      initializer "decidim_half_signup.add_customizations", after: "decidim.action_controller" do
        config.to_prepare do
          # controller
          Decidim::Devise::SessionsController.include(
            Decidim::HalfSignup::SessionsExtensions
          )
          Decidim::Organization.include(
            Decidim::HalfSignup::OrganizationModelExtensions
          )
        end
      end
    end
  end
end
