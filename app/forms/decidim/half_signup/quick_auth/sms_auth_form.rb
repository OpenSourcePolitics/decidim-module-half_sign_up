# frozen_string_literal: true

module Decidim
  module HalfSignup
    module QuickAuth
      class SmsAuthForm < Form
        include Decidim::HalfSignup::QuickAuth::AuthSessionHandler
        mimic :sms_sign_in

        attribute :phone_number, Integer
        attribute :phone_country, String

        validates :phone_country, presence: true
        validates :phone_number, numericality: { greater_than: 0 }, presence: true
        validate :send_code_as_sms # TODO: add if here

        alias organization current_organization

        def send_verification!
          gateway.deliver_code

          generate_sessions!(gateway.code, options)
        rescue Decidim::Sms::GatewayError => e
          @gateway_error_code = e.error_code

          false
        end

        def gateway
          @gateway ||=
            begin
              phone_number = phone_with_country_code(phone_country, phone_number)
              code = generate_code
              if Decidim.config.sms_gateway_service == "Decidim::Sms::Twilio::Gateway"
                Decidim.config.sms_gateway_service.constantize.new(phone_number, code, organization: organization)
              else
                Decidim.config.sms_gateway_service.constantize.new(phone_number, code)
              end
            end
        end

        def generate_code
          SecureRandom.random_number(10_000_000).to_s
        end

        def phone_with_country_code(country_code, phone_number)
          ::Decidim::HalfSignup::PhoneNumberFormatter.new(phone_number: phone_number, iso_country_code: country_code).format
        end

        def options
          {
            phone_country: phone_country,
            phone_number: phone_number
          }
        end
      end
    end
  end
end
