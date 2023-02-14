# frozen_string_literal: true

module Decidim
  module HalfSignup
    module Admin
      class AuthSettingForm < Decidim::Form
        attribute :enable_partial_sms_signup_verification, Boolean, default: false
        attribute :enable_partial_email_signup_verification, Boolean, default: false
        attribute :slug, String

        validates :slug, presence: true
      end
    end
  end
end
