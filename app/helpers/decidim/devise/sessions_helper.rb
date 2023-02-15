# frozen_string_literal: true

module Decidim
  module Devise
    module SessionsHelper
      include Decidim::HalfSignup::PartialSignupSettings

      def half_signup_enabled?
        org_settings = authentication_settings(current_organization)
        org_settings && (org_settings&.enable_partial_email_signup || org_settings&.enable_partial_sms_signup)
      end

      def should_show?
        flash.alert.present? && flash.alert != t("decidim.budgets.voting.index.sign_in_first")
      end
    end
  end
end
