# frozen_string_literal: true

require "spec_helper"

module Decidim
  module HalfSignup
    describe PartialSignupSettings do
      let(:organization) { create(:organization) }
      let!(:resource) do
        Class.new do
          include Decidim::HalfSignup::PartialSignupSettings
        end.new
      end

      describe "#authentication_settings" do
        context "when there is no authentication settings" do
          it "creates the auth_settings" do
            expect do
              resource.authentication_settings(organization)
            end.to change(::Decidim::HalfSignup::AuthSetting, :count).by(1)
          end
        end

        context "when there is auth settings" do
          let!(:auth_settings) { create(:auth_setting, organization: organization) }

          it "returns the current auth settings for the organization" do
            expect do
              resource.authentication_settings(organization)
            end.not_to change(::Decidim::HalfSignup::AuthSetting, :count)
            expect(resource.authentication_settings(organization)).to eq(auth_settings)
          end
        end
      end

      describe "#partial_signup_enabled?" do
        let!(:auth_settings) { create(:auth_setting, organization: organization) }

        it "returns true/false correctly" do
          expect(resource.half_signup_enabled?(organization)).to be(false)
          auth_settings.enable_partial_sms_signup = true
          auth_settings.save
          resource.authentication_settings(organization).reload
          expect(resource.half_signup_enabled?(organization)).to be(true)
        end
      end

      describe "#half_signup_handlers" do
        before do
          allow(resource).to receive(:current_organization).and_return(organization)
        end

        let!(:auth_settings) do
          create(
            :auth_setting,
            organization: organization,
            enable_partial_email_signup: true,
            enable_partial_sms_signup: true
          )
        end

        it "returns the handlers" do
          expect(resource.half_signup_handlers).to contain_exactly("sms", "email")
        end
      end
    end
  end
end
