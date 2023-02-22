# frozen_string_literal: true

module Decidim
  module HalfSignup
    class AuthForm < Form
      attribute :auth_method, String
      attribute :organization, Decidim::Organization

      validates :auth_method, inclusion: { in: %w(sms email) }

      alias organization current_organization
    end
  end
end
