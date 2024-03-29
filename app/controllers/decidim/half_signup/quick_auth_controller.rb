# frozen_string_literal: true

module Decidim
  module HalfSignup
    class QuickAuthController < ::Decidim::Devise::OmniauthRegistrationsController
      include Decidim::HalfSignup::QuickAuth::AuthSessionHandler
      include Decidim::HalfSignup::PartialSignupSettings

      before_action :ensure_authorized, only: [:email, :options]

      def sms
        ensure_enabled_auth("sms")
        @form = form(SmsAuthForm).instance
        init_sessions!({ auth_method: "sms" })
      end

      def email
        ensure_enabled_auth("email")
        @form = form(EmailAuthForm).instance
        init_sessions!({ auth_method: "email" })
      end

      def verification
        @form = set_auth_form.from_params(params.merge(organization: current_organization))
        # in the test, and development environment, and with the Twilio gateway installation,
        # we have to set the organization to nil, since the delivery report can not be sent to the
        # localhost. However, we should set this to the current_organization if production
        SendVerification.call(@form) do
          on(:ok) do |result|
            if sms_auth?
              update_sessions!({ code: result, country: @form.phone_country, phone: @form.phone_number })
              flash[:notice] = I18n.t("success", scope: "decidim.half_signup.quick_auth.sms_verification", phone: formatted_phone_number(@form))
            else
              update_sessions!({ code: result, email: @form.email })
              flash[:notice] = I18n.t("success", scope: "decidim.half_signup.quick_auth.email_verification", email: form.email)
            end
            redirect_to action: "verify"
          end

          on(:invalid) do |error_code|
            flash.now[:alert] = if error_code
                                  sms_sending_error(error_code)
                                else
                                  I18n.t("unknown", scope: "decidim.half_signup.quick_auth.sms_verification")
                                end
            if sms_auth?
              render action: "sms"
            else
              render action: "email"
            end
          end
        end
      end

      def verify
        return redirect_to decidim_half_signup.users_quick_auth_path unless auth_session

        @form = form(VerificationCodeForm).instance
        @verification_code = auth_session["code"]
        @info = set_contact_info
      end

      def authenticate
        return redirect_to(action: "verify") unless ensure_attempts_threshold

        @form = form(VerificationCodeForm).from_params(params.merge(current_locale: current_locale, organization: current_organization))

        @verification_code = auth_session["code"]
        AuthenticateUser.call(form: @form, data: auth_session) do
          on(:ok) do |user|
            flash[:notice] = I18n.t("signed_in", scope: "decidim.half_signup.quick_auth.authenticate_user")
            reset_auth_session
            sign_in_and_redirect user, event: :authentication
          end

          on(:invalid) do |validation_message|
            add_failed_attempt if validation_message.present?
            flash.now[:error] = validation_message
            render :verify
          end
        end
      end

      def update_phone
        @form = form(VerificationCodeForm).from_params(params.merge(current_locale: current_locale, organization: current_organization))

        @verification_code = auth_session["code"]
        UpdateUserPhone.call(form: @form, data: auth_session, user: current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("updated", scope: "decidim.half_signup.quick_auth.authenticate_user")
            reset_auth_session
            redirect_to decidim.account_path
          end

          on(:invalid) do |validation|
            add_failed_attempt if validation == I18n.t("error", scope: "decidim.half_signup.quick_auth.authenticate_user")
            flash.now[:error] = validation
            render :verify
          end
        end
      end

      def resend
        return unless ensure_code_delivery

        @form = set_auth_form.from_params(params_from_previous_attempts.merge(organization: current_organization))

        SendVerification.call(@form) do
          on(:ok) do |result|
            update_sessions!({ code: result })
            flash[:notice] = if sms_auth?
                               I18n.t("success", scope: "decidim.half_signup.quick_auth.sms_verification", phone: formatted_phone_number(@form))
                             else
                               I18n.t("success", scope: "decidim.half_signup.quick_auth.email_verification", email: auth_session["email"])
                             end
            redirect_to action: "verify"
          end

          on(:invalid) do |error_code|
            if sms_auth?
              flash.now[:alert] = sms_sending_error(error_code)
              render action: "sms"
            else
              flash.now[:alert] = I18n.t("error", scope: "decidim.half_signup.quick_auth.email_verification")
              render action: "email"
            end
          end
        end
      end

      def options
        nil
      end

      private

      def ensure_enabled_auth(option)
        return if half_signup_handlers.include? option

        flash[:error] = I18n.t("not_allowed", scope: "decidim.half_signup.quick_auth.options")
        redirect_to decidim.root_path
      end

      def ensure_authorized
        return true if current_user.blank? && handlers_count.positive?

        flash[:error] = I18n.t("not_allowed", scope: "decidim.half_signup.quick_auth.options")
        redirect_to decidim.root_path
        false
      end

      def sms_sending_error(error_code)
        case error_code
        when :invalid_to_number
          I18n.t("invalid_to_number", scope: "decidim.half_signup.quick_auth.sms_verification")
        when :invalid_geo_permission
          I18n.t("invalid_geo_permission", scope: "decidim.half_signup.quick_auth.sms_verification")
        when :invalid_from_number
          I18n.t("invalid_from_number", scope: "decidim.half_signup.quick_auth.sms_verification")
        else
          I18n.t("unknown", scope: "decidim.half_signup.quick_auth.sms_verification")
        end
      end

      def params_from_previous_attempts
        {
          phone_country: auth_session["country"],
          phone_number: auth_session["phone"],
          email: auth_session["email"],
          auth_method: auth_session["method"]
        }
      end

      def send_code_allowed?
        return true unless sms_auth?

        auth_session.present? &&
          auth_session["sent_at"] < 1.minute.ago
      end

      def ensure_code_delivery
        return true if send_code_allowed?

        flash[:error] = I18n.t("not_allowed", scope: "decidim.half_signup.quick_auth.resend_code")
        redirect_to action: "verify"
        false
      end

      def set_auth_form
        if sms_auth?
          form(SmsAuthForm)
        else
          form(EmailAuthForm)
        end
      end

      def set_contact_info
        auth_session["email"] || PhoneNumberFormatter.new(
          phone_number: auth_session["phone"], iso_country_code: auth_session["country"]
        ).format
      end

      def add_failed_attempt
        auth_session["attempts"] += 1
        auth_session["last_attempt"] = Time.current
      end

      def ensure_attempts_threshold
        return true if auth_session["attempts"] < 20

        if auth_session["last_attempt"] <= 2.minutes.ago
          reset_attempts
          return true
        end
        flash[:error] = I18n.t("threshold_exceeded", scope: "decidim.half_signup.quick_auth.authenticate_user")
        false
      end

      def reset_attempts
        auth_session["attempts"] = 0
        auth_session["last_attempt"] = nil
      end
    end
  end
end
