# frozen_string_literal: true

require "spec_helper"

describe Decidim::HalfSignup::SendVerification, type: :command do
  subject { command.call }

  let!(:organization) { create(:organization) }
  let(:command) { described_class.new(form) }
  let(:verification) { "1234" }
  let(:email) { nil }
  let(:phone_number) { nil }
  let(:phone_country) { nil }
  let(:valid) { true }
  let(:form) do
    double(
      valid?: valid,
      auth_method: auth_method,
      organization: organization,
      email: email,
      phone_number: phone_number,
      phone_country: phone_country
    )
  end

  before do
    allow(SecureRandom).to receive(:random_number).and_return(verification)
  end

  describe "when email" do
    let!(:auth_method) { "email" }

    context "when form is not valid" do
      before do
        allow(form).to receive(:valid?).and_return(false)
      end

      it "broadcasts :invlid" do
        expect(subject).to broadcast(:invalid)
        expect(Decidim::HalfSignup::VerificationCodeMailer).not_to receive(:call)
      end
    end

    context "when form is valid" do
      let(:email) { "jadeh@example.org" }

      it "sends the email" do
        expect(subject).to broadcast(:ok, verification)
        expect(Decidim::HalfSignup::VerificationCodeMailer).not_to receive(:verification_code).with(
          email: email,
          verification: verification,
          organization: organization
        )
        # Because of wisper-rspec, the command is called twice and the
        # actionmailer job is therefore enqueued twice. In real use, it will only
        # send one message.
        expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.on_queue("mailers").twice
      end
    end
  end

  describe "when sms" do
    let!(:auth_method) { "sms" }
    let(:gateway) { command.send(:sms_gateway) }

    context "when form is not valid" do
      before do
        allow(form).to receive(:valid?).and_return(false)
      end

      it "broadcasts :invalid" do
        expect(gateway).not_to receive(:deliver_code)
        expect(subject).to broadcast(:invalid)
      end
    end

    context "when form is valid" do
      let!(:phone_number) { 4_577_886_622 }
      let!(:phone_country) { "FI" }

      context "when default gateway" do
        context "when delivers the code" do
          it "delivers the verification code" do
            allow(gateway).to receive(:deliver_code).and_return(true)
            expect(subject).to broadcast(:ok, verification)
          end

          # Note that this spec does not expect any broadcast message to avoid
          # wisper-rspec calling the command by itself.
          it "is only called once" do
            expect(gateway).to receive(:deliver_code).once.and_return(true)
            subject
          end
        end

        context "when fails to deliver" do
          it "delivers the verification code" do
            allow(gateway).to receive(:deliver_code).and_return(false)
            expect(subject).to broadcast(:invalid)
          end

          # Note that this spec does not expect any broadcast message to avoid
          # wisper-rspec calling the command by itself.
          it "is only called once" do
            expect(gateway).to receive(:deliver_code).once.and_return(false)
            subject
          end
        end
      end

      context "when another gateway configured" do
        let(:foo_gateway) do
          Class.new do
            attr_reader :number, :message, :organization

            def initialize(number, message, organization:)
              @number = number
              @message = message
              @organization = organization
            end

            def deliver_code
              false
            end
          end
        end

        before do
          # rubocop:disable Rspec/MessageChain
          allow(Decidim.config).to receive_message_chain(:sms_gateway_service, :constantize).and_return(foo_gateway)
          # rubocop:enable Rspec/MessageChain
        end

        it "does not deliver the verification code" do
          expect(subject).to broadcast(:invalid)
        end

        it "sets the correct values" do
          expect(gateway.number).to eq("+358#{phone_number}")
          expect(gateway.message).to eq("Use code #{verification} to sign in to the platform.")
          expect(gateway.organization).to eq(organization)
        end
      end
    end
  end
end
