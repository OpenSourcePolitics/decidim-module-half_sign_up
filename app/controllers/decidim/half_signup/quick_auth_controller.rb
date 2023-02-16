# frozen_string_literal: true

module Decidim
  module HalfSignup
    class QuickAuthController < ::Decidim::Devise::OmniauthRegistrationsController
      # TODO: Ensure user is not logged in

      def sms
        @form = form(::Decidim::HalfSignup::QuickAuth::SmsAuthForm).instance
      end

      def email
        @form = form(::Decidim::HalfSignup::QuickAuth::EmailAuthForm).instance
      end

      def verify

      end

      def resend_code
        params[:auth_method] # sms|email
      end

      def options; end

      private

      def auth_method
        params[:auth_method]
      end

      def sms_auth?
        auth_method == "sms"
      end

      def email_auth?
        auth_method == "email"
      end
    end
  end
end
