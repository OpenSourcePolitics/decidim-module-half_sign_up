# frozen_string_literal: true

module Decidim
  module HalfSignup
    class VerificationCodeForm < Form
      attribute :verification, String
      attribute :current_locale, String
      attribute :organization, Decidim::Organization

      validates :verification, presence: true
    end
  end
end
