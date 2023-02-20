# frozen_string_literal: true

module Decidim
  module HalfSignup
    class QuickAuthController < ::Decidim::Devise::OmniauthRegistrationsController
      include Decidim::HalfSignup::QuickAuth::AuthSessionHandler
      # TODO: Ensure user is not logged in

      def sms
        @form = form(SmsAuthForm).instance
        init_sessions!({ auth_method: "sms" })
      end

      def email
        @form = form(EmailAuthForm).instance
        init_sessions!({ auth_method: "email" })
      end

      def sms_verification
        @form = form(SmsAuthForm).from_params(params)
        # in the test, and development environment, and with the Twilio gateway installation,
        # we have to set the organization to nil, since the delivery report can not be sent to the
        # localhost. However, we should set this to the current_organization if production
        SendSmsCode.call(@form, organization: set_organization) do
          on(:ok) do |result|
            update_sessions!({ code: result, country: @form.phone_country, phone: @form.phone_number })
            flash[:notice] = I18n.t(".success", scope: "decidim.half_signup.quick_auth.sms_verification", phone: formatted_phone_number(@form))
            redirect_to action: "verify"
          end

          on(:invalid) do |error_code|
            flash.now[:alert] = sms_sending_error(error_code)
            render action: "sms"
          end
        end
      end

      def verify
        @form = form(VerificationCodeForm).instance
        @verification_code = auth_session["code"]
      end

      def email_verification
        form(EmailAuthForm).from_params(params)
      end

      def authenticate
        @form = form(VerificationCodeForm).from_params(params)
        AuthenticateUser.call(form: @form, data: auth_session, organization: current_organization) do
          on(:ok) do |user|
            raise user.inspect
          end

          on(:invalid) do
            flash.now[:error] = I18n.t(".error", scope: "decidim.half_signup.quick_auth.authenticate_user")
            render :verify
          end
        end
      end

      def resend_code
        # params[:auth_method] # sms|email
      end

      def options; end

      private

      def set_organization
        return current_organization unless twilio_gateway?
        return nil if Rails.env.test? || Rails.env.development?

        current_organization
      end

      def twilio_gateway?
        Decidim.config.sms_gateway_service == "Decidim::Sms::Twilio::Gateway"
      end

      def formatted_phone_number(form)
        PhoneNumberFormatter.new(phone_number: form.phone_number, iso_country_code: form.phone_country).format
      end

      def sms_sending_error(error_code)
        case error_code
        when :invalid_to_number
          I18n.t(".invalid_to_number", scope: "decidim.half_signup.quick_auth.sms_verification")
        when :invalid_geo_permission
          I18n.t(".invalid_geo_permission", scope: "decidim.half_signup.quick_auth.sms_verification")
        when :invalid_from_number
          I18n.t(".invalid_from_number", scope: "decidim.half_signup.quick_auth.sms_verification")
        else
          I18n.t(".unknown", scope: "decidim.half_signup.quick_auth.sms_verification")
        end
      end
    end
  end
end
