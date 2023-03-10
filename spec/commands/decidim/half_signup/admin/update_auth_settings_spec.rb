# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::HalfSignup::Admin::UpdateAuthSettings do
  let!(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let!(:auth_settings) { create(:auth_setting) }

  let(:form) do
    double(
      invalid?: false,
      current_user: user,
      enable_partial_sms_signup: true,
      enable_partial_email_signup: true
    )
  end
  let(:command) { described_class.new(auth_settings, form) }

  describe "#call" do
    subject { command.call }

    context "with valid form data" do
      it "broadcasts :ok" do
        expect(subject).to broadcast(:ok)
      end

      it "updates the authentication settings" do
        expect(auth_settings.enable_partial_sms_signup).to be(false)
        expect(auth_settings.enable_partial_email_signup).to be(false)
        expect(Decidim.traceability)
          .to receive(:update!)
          .with(auth_settings, form.current_user, kind_of(Hash))
          .and_call_original
        subject
        auth_settings.reload
        expect(auth_settings.enable_partial_sms_signup).to be(true)
        expect(auth_settings.enable_partial_email_signup).to be(true)
      end
    end

    context "with invalid form data" do
      before do
        allow(form).to receive(:invalid?).and_return(true)
      end

      it "does broadcasts :invalid" do
        expect(subject).to broadcast(:invalid)
      end
    end
  end
end
