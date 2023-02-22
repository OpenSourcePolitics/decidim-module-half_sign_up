# frozen_string_literal: true

module Decidim
  module HalfSignup
    class SmsAuthForm < AuthForm
      mimic :sms_sign_in

      attribute :phone_number, Integer
      attribute :phone_country, String

      validates :phone_number, numericality: { greater_than: 0 }, presence: true
      validates :phone_country, presence: true
    end
  end
end
