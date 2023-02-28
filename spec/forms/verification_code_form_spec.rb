# frozen_string_literal: true

require "spec_helper"

module Decidim::HalfSignup
  describe VerificationCodeForm do
    subject(:form) { described_class.from_params(attributes) }
    let(:organization) { create(:organization) }
    let(:verification) { "dummy verification" }
    let(:current_locale) { "en" }
    let(:attributes) do
      {
        verification: verification,
        organization: organization,
        current_locale: current_locale
      }
    end

    context "when form is validd" do
      it { is_expected.to be_valid }
    end

    context "when verificationis is not valid" do
      let!(:verification) { nil }

      it { is_expected.not_to be_valid }
    end
  end
end
