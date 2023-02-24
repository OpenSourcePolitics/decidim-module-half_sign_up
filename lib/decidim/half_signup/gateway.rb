# frozen_string_literal: true

# A Service to send SMS to Twilio provider to make capability of sending sms with Twilio gateway
module Decidim
  module HalfSignup
    class GatewayError < StandardError
      attr_reader :error_code

      def initialize(message = "Gateway error", error_code = :unknown)
        @error_code = error_code
        super(message)
      end
    end
  end
end
