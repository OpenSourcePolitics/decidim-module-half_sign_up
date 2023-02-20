# frozen_string_literal: true

module Decidim
  module HalfSignup
    module QuickAuth
      module TokenGenerator
        def generate_token(payload)
          Digest::MD5.hexdigest(
            [
              payload.to_s,
              Rails.application.secrets.secret_key_base
            ].join(":")
          )
        end
      end
    end
  end
end
