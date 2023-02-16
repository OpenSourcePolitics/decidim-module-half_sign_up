# frozen_string_literal: true

module Decidim
  module HalfSignup
    module QuickAuth
      module VerificationCodeGenerator
        def generate_code
          SecureRandom.random_number(10_000_000).to_s
        end
      end
    end
  end
end
