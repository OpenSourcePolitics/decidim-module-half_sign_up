# frozen_string_literal: true

module Decidim
  module HalfSignup
    class EmailAuthForm < AuthForm
      mimic :email_sign_in

      attribute :email, String

      validates :email, presence: true, "valid_email_2/email": { disposable: true }
    end
  end
end
