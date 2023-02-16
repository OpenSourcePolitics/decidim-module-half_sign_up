# frozen_string_literal: true

module Decidim
  module HalfSignup
    class EmailAuthForm < Form
      mimic :sms_sign_in

      attribute :email, String

      validates :email, presence: true, "valid_email_2/email": { disposable: true }
      validates :send_code_as_email
    end
  end
end
