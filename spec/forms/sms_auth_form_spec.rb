# frozen_string_literal: true

require "spec_helper"

module Decidim::HalfSignup
  describe SmsAuthForm do
    subject(:form) { described_class.from_params(attributes) }
    let(:organization) { create(:organization) }
    let(:phone_number) { 45_423_456 }
    let(:phone_country) { "FI" }
    let(:attributes) do
      {
        auth_method: "sms",
        phone_number: phone_number,
        phone_country: phone_country
      }
    end

    context "when valid" do
      it { is_expected.to be_valid }
    end

    describe "#phone_number" do
      context "when not present" do
        let!(:phone_number) { nil }

        it { is_expected.not_to be_valid }
      end

      context "when not positive" do
        let!(:phone_number) { 0 }

        it { is_expected.not_to be_valid }
      end
    end

    describe "#phone_country" do
      context "when not present" do
        let!(:phone_country) { "" }

        it { is_expected.not_to be_valid }
      end
    end

    context "when phone country is FR" do
      let!(:phone_country) { "FR" }

      context "with phone number format is valid" do
        let(:phone_number) { "0612345678" }

        it { is_expected.to be_valid }
      end

      context "with phone number format is unvalid" do
        let(:phone_number) { "0112345678" }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
