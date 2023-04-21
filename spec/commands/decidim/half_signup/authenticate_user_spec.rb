# frozen_string_literal: true

require "spec_helper"
module Decidim
  module HalfSignup
    describe AuthenticateUser, type: :command do
      subject { command.call }

      let!(:organization) { create(:organization) }
      let(:command) { described_class.new(form: form, data: data) }
      let(:verification) { "1234" }
      let(:valid) { true }
      let(:form) do
        double(
          valid?: valid,
          organization: organization,
          current_locale: "en",
          verification: verification
        )
      end
      let!(:data) do
        {
          "code" => "1234",
          "country" => nil,
          "phone" => nil,
          "email" => nil,
          "method" => nil,
          "verified" => false,
          "sent_at" => Time.current
        }
      end

      context "when invalid form" do
        let!(:valid) { false }

        it "broadcasts invalid" do
          expect(subject).to broadcast(:invalid)
        end
      end

      context "when code is not valid anymore" do
        before do
          data["sent_at"] = 5.minutes.ago
        end

        it "broadcasts invalid" do
          expect(subject).to broadcast(:invalid)
        end
      end

      context "when invalid verification" do
        let!(:verification) { "wrong code" }

        it "broadcast invalid" do
          expect(subject).to broadcast(:invalid)
        end
      end

      context "when form is valid" do
        context "when sms_auth" do
          context "when user exists" do
            before do
              user = create(:user, :confirmed, organization: organization, phone_number: "4578878784", phone_country: "FI")
              data["phone"] = user.phone_number
              data["country"] = user.phone_country
              data["method"] = "sms"
            end

            it "returns the user" do
              user = Decidim::User.last
              expect(subject).to broadcast(:ok, user)
            end
          end
        end

        context "when email_auth" do
          context "when user exists" do
            before do
              user = create(:user, :confirmed, organization: organization, phone_number: "4578878784", phone_country: "FI")
              data["email"] = user.email
              data["method"] = "email"
            end

            it "returns the user" do
              user = Decidim::User.last
              expect(subject).to broadcast(:ok, user)
            end
          end

          context "when user does not exist" do
            before do
              data["email"] = "someone@example.com"
              data["method"] = "email"
            end

            it "returns the user" do
              subject
              user = Decidim::User.last
              expect(user.email).to eq("someone@example.com")
              expect(subject).to broadcast(:ok, user)
            end
          end
        end
      end
    end
  end
end
