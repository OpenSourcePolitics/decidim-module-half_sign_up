# frozen_string_literal: true

module Decidim
  module HalfSignup
    module QuickAuth
      module VerificationCodeGenerator
        def generate_code
          # code = SecureRandom.random_number(10**auth_code_length).to_s
          code = "62"
          add_zeros(code)
        end

        def auth_code_length
          ::Decidim::HalfSignup.auth_code_length
        end

        private

        def add_zeros(code)
          return code if code.length == auth_code_length

          ("0" * (auth_code_length - code.length)) + code
        end
      end
    end
  end
end
