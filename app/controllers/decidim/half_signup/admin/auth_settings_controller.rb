# frozen_string_literal: true

module Decidim
  module HalfSignup
    module Admin
      class AuthSettingsController < Decidim::Admin::ApplicationController
        include Decidim::HalfSignup::PartialSignupSettings

        layout "decidim/admin/settings"
        def edit
          enforce_permission_to :update, :organization, organization: current_organization

          @form = form(AuthSettingForm).from_model(authentication_settings(current_organization))
        end

        def update
          enforce_permission_to :update, :organization, organization: current_organization

          @form = form(AuthSettingForm).from_params(params)

          UpdateAuthSettings.call(authentication_settings(current_organization), @form) do
            on(:ok) do
              flash[:notice] = I18n.t("organization.update.success", scope: "decidim.admin")
              redirect_to action: :edit
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("organization.update.error", scope: "decidim.admin")
              render :edit
            end
          end
        end
      end
    end
  end
end
