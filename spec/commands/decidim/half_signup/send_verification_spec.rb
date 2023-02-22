# frozen_string_literal: true

require "spec_helper"

describe Decidim::HalfSignup::SendVerification, type: :command do
  let(:organization) { create(:organization) }
  let(:command) { described_class.new(form, auth_method: auth_method) }

  describe "when email" do
    subject { command.call }

    let(:auth_method) { "email" }
    let(:form) do
      double(
        invalid?: false,
        auth_method: "email",
        organization: organization,
        email: "jdoe@example.org"
      )
    end

    it "sends the email" do
      expect(subject).to broadcast(:ok, an_instance_of(ActionMailer::MailDeliveryJob))

      # Because of wisper-rspec, the command is called twice and the
      # actionmailer job is therefore enqueued twice. In real use, it will only
      # send one message.
      expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.on_queue("mailers").twice
    end
  end
end
