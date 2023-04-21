# frozen_string_literal: true

require "spec_helper"

module Decidim::HalfSignup
  describe AuthForm do
    subject(:form) { described_class.from_params(attributes) }

    let(:organization) { create(:organization) }
    let(:auth_method) { "sms" }
    let(:attributes) do
      {
        auth_method: auth_method,
        organization: organization
      }
    end

    context "when auth_method is invalid" do
      let!(:auth_method) { "foo" }

      it { is_expected.not_to be_valid }
    end

    context "when auth_method is sms" do
      it { is_expected.to be_valid }
    end

    context "when auth_method is email" do
      let!(:auth_method) { "email" }

      it { is_expected.to be_valid }
    end
  end
end
