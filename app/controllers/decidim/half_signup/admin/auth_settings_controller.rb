# frozen_string_literal: true

module Decidim
  module HalfSignup
    module Admin
      class AuthSettingsController < Decidim::Admin::ApplicationController
        layout "decidim/admin/settings"
        def edit
          enforce_permission_to :update, :organization, organization: current_organization

          @form = form(AuthSettingForm).from_model(authentication_settings)
        end

        def update
          enforce_permission_to :update, :organization, organization: current_organization

          @form = form(AuthSettingForm).from_params(params)

          UpdateAuthSettings.call(authentication_settings, @form) do
            on(:ok) do
              flash[:notice] = I18n.t("organization.update.success", scope: "decidim.admin")
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("organization.update.error", scope: "decidim.admin")
            end
          end
          render :edit
        end

        private

        def authentication_settings
          @authentication_settings ||= ::Decidim::HalfSignup::AuthSetting.find_or_create_by!(
            slug: "authentication_settings",
            organization: current_organization
          )
        end
      end
    end
  end
end
