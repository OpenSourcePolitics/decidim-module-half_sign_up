# frozen_string_literal: true

module Decidim
  module HalfSignup
    module QuickAuth
      module VerificationCodeGenerator
        def generate_code
          SecureRandom.random_number(10**auth_code_length).to_s
        end

        def auth_code_length
          ::Decidim::HalfSignup.auth_code_length
        end
      end
    end
  end
end
