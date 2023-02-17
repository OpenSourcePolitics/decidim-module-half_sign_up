# frozen_string_literal: true

module Decidim
  module HalfSignup
    # This is the engine that runs on the public interface of `HalfSignup`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::HalfSignup::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        scope "/organization" do
          resources :auth_settings, param: :slug, only: [:edit, :update]
        end
      end

      initializer "decidim_half_signup.mount_routes", before: "decidim_admin.mount_routes" do
        Decidim::Admin::Engine.routes.append do
          mount Decidim::HalfSignup::AdminEngine => "/"
        end
      end

      initializer "decidim_half_signup.add_half_signup_menu_to_admin", before: "decidim_admin.admin_settings_menu" do
        Decidim.menu :admin_settings_menu do |menu|
          # /organization/
          menu.add_item :edit_organization,
                        I18n.t("menu.auth_settings", scope: "decidim.half_signup"),
                        decidim_half_signup_admin.edit_auth_setting_path(slug: "authentication_settings"),
                        position: 1.1,
                        if: allowed_to?(:update, :organization, organization: current_organization),
                        active: is_active_link?(decidim_half_signup_admin.edit_auth_setting_path(
                                                  slug: "authentication_settings"
                                                ))
        end
      end

      def load_seed
        nil
      end
    end
  end
end
