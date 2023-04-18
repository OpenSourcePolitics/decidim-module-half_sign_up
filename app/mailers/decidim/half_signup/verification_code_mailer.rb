# frozen_string_literal: true

module Decidim
  module HalfSignup
    class VerificationCodeMailer < ApplicationMailer
      # Public: Sends the verification email to the provided email address.
      #
      # email - The email address the veirfication code is to be sent to.
      # verification = The verification code  to be sent.
      # locale - The locale that will be used for the email content (optional).
      #
      # Returns nothing.
      def verification_code(email:, verification:, organization:)
        @verification = verification.strip
        @organization = organization

        I18n.with_locale(locale || organization.default_locale) do
          mail(to: email, subject: I18n.t("subject", scope: "decidim.half_signup.quick_auth.email_verification", verification: verification))
        end
      end
    end
  end
end
