# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module HalfSignup
    # This is the engine that runs on the public interface of half_signup.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::HalfSignup
      routes do
        devise_scope :user do
          # We need to define the routes to be able to show the sign in views
          # within Decidim.
          match(
            "/users/quick_auth",
            to: "quick_auth#options",
            via: [:get, :post]
          )
          namespace :users_quick_auth, path: "users/quick_auth", module: "quick_auth" do
            get :sms, :email, :resend, :verify
            post :verification, :authenticate, :update_phone
          end
        end
      end

      initializer "decidim_half_signup.mount_routes", before: :add_routing_paths do
        # Mount the engine routes to Decidim::Core::Engine because otherwise
        # they would not get mounted properly. Note also that we need to prepend
        # the routes in order for them to override Decidim's own routes for the
        # authentication.
        Decidim::Core::Engine.routes.prepend do
          mount Decidim::HalfSignup::Engine => "/"
        end
      end

      initializer "HalfSignup.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim_half_signup.add_customizations", after: "decidim.action_controller" do
        config.to_prepare do
          # this has to be added because of a bug in decidim core, other 'valid_email2' gem will not be
          # available through the account form, which leads an error.
          Decidim::User # rubocop:disable Lint/Void

          # forms
          Decidim::AccountForm.include(Decidim::HalfSignup::AccountFormExtensions)

          Decidim::Organization.include(
            Decidim::HalfSignup::OrganizationModelExtensions
          )

          Decidim::Menu.include(Decidim::HalfSignup::MenuExtensions)
        end
      end

      initializer "decidim_half_signup.middleware" do |app|
        app.middleware.use Decidim::HalfSignup::HalfSignupMiddleware
      end
    end
  end
end
