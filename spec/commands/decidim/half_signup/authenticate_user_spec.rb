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
      let(:session) { {} }
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
          "country" => country,
          "phone" => phone,
          "email" => nil,
          "method" => method,
          "verified" => false,
          "sent_at" => Time.current
        }
      end
      let(:user) { create(:user, :confirmed, organization: organization, phone_number: phone_number, phone_country: phone_country) }
      let(:phone_number) { "123456" }
      let(:phone_country) { "FI" }
      let(:phone) { nil }
      let(:country) { nil }
      let(:method) { nil }

      before do
        allow_any_instance_of(described_class).to receive(:session).and_return(session)
      end

      context "when sms_auth" do
        let(:method) { "sms" }
        let(:phone) { "654321" }
        let(:country) { "FI" }

        context "when session is present" do
          let(:session) { { user_id: user.id } }

          before do
            allow_any_instance_of(described_class).to receive(:session).and_return(session)
          end

          context "and user_id exists" do
            context "and phone number is not present on user" do
              let(:phone_number) { nil }
              let(:phone_country) { nil }

              it "updates the phone number and phone country" do
                subject
                user = Decidim::User.last
                expect(user.phone_number).to eq("654321")
                expect(user.phone_country).to eq("FI")
                expect(subject).to broadcast(:ok, user)
              end
            end

            context "and phone number is present on user" do
              it "broadcast user" do
                subject
                user = Decidim::User.last
                expect(subject).to broadcast(:ok, user)
              end
            end
          end

          context "and user_id does not exist" do
            let(:session) { { user_id: "999999999999" } }

            context "and phone number is not present on user" do
              let(:phone_number) { nil }
              let(:phone_country) { nil }

              it "updates the phone number and phone country" do
                subject
                new_user = Decidim::User.last
                expect(new_user.id).not_to eq(user.id)
                expect(new_user.phone_number).to eq("654321")
                expect(new_user.phone_country).to eq("FI")
                expect(subject).to broadcast(:ok, new_user)
              end
            end
          end
        end

        context "when user exists" do
          before do
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
            user = create(:user, :confirmed, organization: organization, phone_number: "123456", phone_country: "FI")
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
    end
  end
end
