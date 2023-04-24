# frozen_string_literal: true

require "spec_helper"

module Decidim
  module HalfSignup
    describe VerificationCodeMailer, type: :mailer do
      let(:mail) do
        described_class.verification_code(
          email: email,
          verification: verification,
          organization: organization
        )
      end
      let(:organization) { create(:organization) }
      let(:verification) { "11223344" }
      let(:email) { "dummy_email@example.org" }

      describe "#verification_code" do
        it "delivers the email to the provided email" do
          expect(mail.to).to eq(Array(email))
        end

        it "sets a subject" do
          expect(mail.subject).to eq("Your sing in code is: 11223344")
        end

        it "sets the content" do
          expect(mail).to have_content("Confirm your email address by entering the sign in code below in the field provided on the service.")
          expect(mail).to have_content("Your sign in code is:")
          expect(mail).to have_content(verification)
        end
      end
    end
  end
end
