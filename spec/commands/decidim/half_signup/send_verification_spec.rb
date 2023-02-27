# frozen_string_literal: true

require "spec_helper"

describe Decidim::HalfSignup::SendVerification, type: :command do
  let!(:organization) { create(:organization) }
  let(:command) { described_class.new(form) }
  let(:verification) { "1234567" }
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
    subject { command.call }

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

    describe "when sms" do
      subject { command.call }

      let!(:auth_method) { "sms" }

      context "when form is not valid" do
        before do
          allow(form).to receive(:valid?).and_return(false)
        end

        it "broadcasts :invlid" do
          expect(subject).to broadcast(:invalid)
          expect(Decidim.config.sms_gateway_service.constantize).not_to receive(:call)
        end
      end

      context "when form is valid" do
        let!(:phone_number) { 4_577_886_622 }
        let!(:phone_country) { "FI" }

        context "when default gateway" do
          let(:gatewayer) { Decidim::Verifications::Sms::ExampleGateway }

          context "when delivers the code" do
            before do
              allow_any_instance_of(gatewayer).to receive(:deliver_code).and_return(true) # rubocop:disable Rspec/AnyInstance
            end

            it "delivers the verification code" do
              expect(subject).to broadcast(:ok, verification)
            end
          end

          context "when fails to deliver" do
            before do
              allow_any_instance_of(gatewayer).to receive(:deliver_code).and_return(false) # rubocop:disable Rspec/AnyInstance
            end

            it "delivers the verification code" do
              expect(subject).to broadcast(:invalid)
            end
          end
        end

        context "when another gateway configured" do
          let(:foo_gateway) do
            Class.new do
              def initialize(bar, bas, organization:)
                # a dummy method for initialize
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
        end
      end
    end
  end
end
