# frozen_string_literal: true

require "spec_helper"

describe Decidim::HalfSignup::UpdateUserPhone, type: :command do
  subject { command.call }

  let!(:organization) { create(:organization) }
  let(:command) { described_class.new(form: form, data: data, user: user) }
  let(:user) { nil }
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
    let!(:phone_number) { "4578878784" }
    let!(:phone_country) { "FI" }

    before do
      data["phone"] = phone_number
      data["country"] = phone_country
      data["method"] = "sms"
    end

    context "when user does not exist" do
      it "returns invalid" do
        expect(subject).to broadcast(:invalid, "You are not authorized to perform this action.")
      end
    end

    context "when user exists and has not added phone number before" do
      let!(:user) { create(:user, :confirmed, organization: organization) }
      # user = create(:user, :confirmed, organization: organization, phone_number: "4578878784", phone_country: "FI")

      it "adds the phone number to their account" do
        expect(subject).to broadcast(:ok)
        expect(user.phone_number).to eq("4578878784")
        expect(user.phone_country).to eq("FI")
      end
    end
  end
end
