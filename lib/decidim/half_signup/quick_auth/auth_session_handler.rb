# frozen_string_literal: true

module Decidim
  module HalfSignup
    module QuickAuth
      module AuthSessionHandler
        def reset_auth_session
          session&.delete(:auth_attempt)
        end

        def generate_sessions!(code, options)
          session[:auth_attempt] = {
            code: code,
            sent_at: Time.current,
            country: options&.phone_country,
            phone: options&.phone_number,
            email: options&.email,
            verified: false
          }
        end

        def update_sessions!(result)
          auth_session.merge!(verification_code: result, sent_at: Time.current)
        end

        def auth_session
          session[:auth_attempt].transform_keys(&:to_s)
        end
      end
    end
  end
end
