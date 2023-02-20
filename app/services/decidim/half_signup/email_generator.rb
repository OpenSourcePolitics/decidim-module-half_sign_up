# frozen_string_literal: true

module Decidim
  module HalfSignup
    class EmailGenerator
      include Decidim::HalfSignup::QuickAuth::TokenGenerator

      def initialize(organization, phone_country, phone_number)
        @organization = organization
        @phone_country = phone_country
        @phone_number = phone_number
      end

      def generate
        "quick_auth-#{generate_token(token_data)}@#{organization.host}"
      end

      private

      attr_reader :organization, :phone_country, :phone_number

      def token_data
        "#{phone_country}-#{phone_number}"
      end
    end
  end
end
