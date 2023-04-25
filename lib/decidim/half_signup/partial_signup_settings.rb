# frozen_string_literal: true

module Decidim
  module HalfSignup
    module PartialSignupSettings
      def authentication_settings(organization)
        @authentication_settings ||= ::Decidim::HalfSignup::AuthSetting.find_or_create_by!(
          slug: "authentication_settings",
          organization: organization
        )
      end

      def half_signup_enabled?(organization)
        auth_settings = authentication_settings(organization)
        return false unless auth_settings

        auth_settings&.enable_partial_email_signup || auth_settings&.enable_partial_sms_signup
      end

      def half_signup_handlers
        @half_signup_handlers ||= begin
          settings = authentication_settings(current_organization)

          [].tap do |array|
            array << "email" if settings&.enable_partial_email_signup
            array << "sms" if settings&.enable_partial_sms_signup
          end
        end
      end

      def handlers_count
        half_signup_handlers.length
      end
    end
  end
end
