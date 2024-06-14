# frozen_string_literal: true

module Decidim
  module HalfSignup
    class SmsAuthForm < AuthForm
      mimic :sms_auth

      attribute :phone_number, Integer
      attribute :phone_country, String

      validates :phone_number, numericality: { greater_than: 0 }, presence: true
      validate :validate_phone_number_format, if: -> { phone_country == "FR" }
      validates :phone_country, presence: true

      private

      def validate_phone_number_format
        phone_number_str = phone_number.to_s
        return if phone_number_str.match?(/\A(0[67]|[67])\d{8}\z/)

        errors.add(:phone_number, I18n.t("decidim.half_signup.quick_auth.sms.invalid_phone"))
      end
    end
  end
end
