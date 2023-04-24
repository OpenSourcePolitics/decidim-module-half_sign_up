# frozen_string_literal: true

module Decidim
  module HalfSignup
    class SendVerification < Decidim::Command
      include Decidim::HalfSignup::QuickAuth::VerificationCodeGenerator

      def initialize(form)
        @form = form
      end

      def call
        return broadcast(:invalid) unless @form.valid?

        if @form.auth_method == "sms"
          result = send_sms_verification!
          return broadcast(:invalid, @sms_gateway_error_code) unless result
        else
          result = send_email_verification!
          return broadcast(:invalid) unless result
        end

        broadcast(:ok, result)
      end

      private

      attr_reader :form

      def verification_code
        @verification_code ||= generate_code
      end

      def send_sms_verification!
        verification_code if sms_gateway.deliver_code
      rescue Decidim::HalfSignup::GatewayError => e
        @sms_gateway_error_code = e&.error_code

        false
      end

      def sms_gateway
        @sms_gateway ||=
          begin
            phone_number = phone_with_country_code(form.phone_country, form.phone_number)

            Decidim.config.sms_gateway_service.constantize.new(
              phone_number,
              I18n.t("text_message", scope: "decidim.half_signup.quick_auth.sms_verification", verification: verification_code),
              **gateway_context
            )
          end
      end

      def custom_gateway?
        Decidim.config.sms_gateway_service.constantize.instance_method(:initialize).parameters.count > 2
      end

      # We can provide organization if the gateway allows extra parameters.
      # This is required by some of the gateways, such as Twilio.
      def gateway_context
        return {} if Rails.env.development? || Rails.env.test?
        return {} unless custom_gateway?

        { organization: form.organization }
      end

      def formatted_phone_number(form)
        PhoneNumberFormatter.new(phone_number: form.phone_number, iso_country_code: form.phone_country).format
      end

      def phone_with_country_code(country_code, phone_number)
        PhoneNumberFormatter.new(phone_number: phone_number, iso_country_code: country_code).format
      end

      def send_email_verification!
        return false unless Decidim::HalfSignup::VerificationCodeMailer
                            .verification_code(
                              email: form.email,
                              verification: verification_code,
                              organization: form.organization
                            ).deliver_later

        verification_code
      end
    end
  end
end
