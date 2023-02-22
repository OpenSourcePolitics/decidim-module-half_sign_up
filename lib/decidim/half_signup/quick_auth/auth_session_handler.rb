# frozen_string_literal: true

module Decidim
  module HalfSignup
    module QuickAuth
      module AuthSessionHandler
        def reset_auth_session
          session&.delete(:auth_attempt)
        end

        def init_sessions!(options)
          session[:auth_attempt] = {
            code: options[:code] || nil,
            country: options[:phone_country] || nil,
            phone: options[:phone_number] || nil,
            email: options[:email] || nil,
            method: options[:auth_method],
            verified: false,
            sent_at: nil
          }
        end

        def update_sessions!(options)
          options = options.transform_keys(&:to_s)
          options.each do |key, value|
            auth_session[key] = value if auth_session.has_key?(key)
          end
          auth_session.merge!(sent_at: Time.current)
        end

        def auth_session
          session[:auth_attempt]
        end

        def auth_method
          auth_session["method"]
        end

        def sms_auth?
          auth_session["method"] == "sms"
        end
      end
    end
  end
end
