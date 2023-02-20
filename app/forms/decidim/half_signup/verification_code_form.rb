# frozen_string_literal: true

module Decidim
  module HalfSignup
    class VerificationCodeForm < Form
      attribute :verification, String

      validates :verification, presence: true
    end
  end
end
