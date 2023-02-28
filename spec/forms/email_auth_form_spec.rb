# frozen_string_literal: true

require "spec_helper"

module Decidim::HalfSignup
  describe EmailAuthForm do
    subject(:form) { described_class.from_params(attributes) }
    let(:email) { "invalid_email@example" }
    let(:attributes) do
      {
        auth_method: "email",
        email: email
      }
    end

    context "when email is invalid" do
      it { is_expected.not_to be_valid }
    end

    context "when email is valid" do
      let!(:email) { "valid_email@example.org" }

      it { is_expected.to be_valid }
    end
  end
end
