# frozen_string_literal: true

module Decidim
  module HalfSignup
    class AuthForm < Form
      attribute :auth_method, String
      attribute :organization

      validates :auth_method, inclusion: { in: %w(sms email) }
    end
  end
end
