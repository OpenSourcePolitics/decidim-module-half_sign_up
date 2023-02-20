# frozen_string_literal: true

module Decidim
  module HalfSignup
    class SendSmsCode < Decidim::Command
      include Decidim::HalfSignup::QuickAuth::VerificationCodeGenerator
      include Decidim::HalfSignup::QuickAuth::AuthSessionHandler

      def initialize(form, organization: nil)
        @form = form
        @organization = organization
      end

      def call
        return broadcast(:invalid) if @form.invalid?

        begin
          result = send_sms_verification!
          return broadcast(:invalid, @gateway_error_code) unless result

          broadcast(:ok, result)
        end
      end

      private

      attr_reader :form, :organization

      def send_sms_verification!
        gateway.deliver_code

        gateway.code
      rescue Decidim::Sms::GatewayError => e
        @gateway_error_code = e.error_code

        false
      end

      def gateway
        @gateway ||=
          begin
            phone_number = phone_with_country_code(form.phone_country, form.phone_number)
            code = generate_code
            # We need to provide  the organization if the gateway is twilio.
            if Decidim.config.sms_gateway_service == "Decidim::Sms::Twilio::Gateway"
              Decidim.config.sms_gateway_service.constantize.new(phone_number, code, organization: organization)
            else
              Decidim.config.sms_gateway_service.constantize.new(phone_number, code)
            end
          end
      end

      def phone_with_country_code(country_code, phone_number)
        PhoneNumberFormatter.new(phone_number: phone_number, iso_country_code: country_code).format
      end
    end
  end
end
