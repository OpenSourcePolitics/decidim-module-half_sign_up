# frozen_string_literal: true

module Decidim
  module HalfSignup
    module Admin
      class AuthSettingsController < Decidim::Admin::ApplicationController
        def edit
          enforce_permission_to :update, :organization, organization: current_organization

          @form = form(AuthSettingForm).from_model(authentication_settings)
        end

        def update
          enforce_permission_to :update, :organization, organization: current_organization
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
