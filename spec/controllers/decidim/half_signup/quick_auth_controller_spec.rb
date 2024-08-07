# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::HalfSignup::QuickAuthController, type: :controller do
  routes { Decidim::HalfSignup::Engine.routes }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:organization) { create(:organization) }
  let(:decidim_half_signup) { Decidim::HalfSignup::Engine.routes.url_helpers }
  let(:phone) { nil }
  let(:country) { nil }
  let(:email) { nil }
  let(:method) { nil }
  let(:verified) { nil }
  let(:last_attempt) { nil }
  let(:attempts) { 0 }
  let!(:correct_code) { "correct code" }
  let!(:wrong_code) { "wrong code" }
  let(:sms_gateway_service) { "Decidim::Verifications::Sms::ExampleGateway" }
  let(:auth_session) do
    {
      "code" => "correct code",
      "country" => country,
      "phone" => phone,
      "email" => email,
      "method" => method,
      "verified" => verified,
      "attempts" => attempts,
      "last_attempt" => last_attempt,
      "sent_at" => Time.current
    }
  end

  before do
    request.env["decidim.current_organization"] = organization
    request.env["devise.mapping"] = ::Devise.mappings[:user]
    request.session[:auth_attempt] = auth_session

    allow(Decidim.config).to receive(:sms_gateway_service).and_return(sms_gateway_service)
  end

  after do
    allow(Decidim.config).to receive(:sms_gateway_service).and_call_original
  end

  describe "GET #sms" do
    context "when user is not authorized" do
      let!(:auth_settings) { create(:auth_setting, organization: organization) }

      context "when the sms_auth_settings is disabled" do
        it "redirects the user" do
          get :sms
          expect(response).to redirect_to("/")
          expect(flash[:error]).to eq("You are not allowed to perform this action.")
        end
      end

      context "when the sms_auth settings is enabled" do
        before do
          auth_settings.enable_partial_sms_signup = true
          auth_settings.save
        end

        it "renders the :sms template" do
          get :sms
          expect(response).to render_template(:sms)
        end
      end

      context "when user is logged in" do
        before do
          auth_settings.enable_partial_sms_signup = true
          auth_settings.save
          sign_in user
        end

        it "renders the template" do
          get :sms
          expect(response).to render_template(:sms)
        end
      end
    end
  end

  describe "GET #email" do
    context "when user is not authorized" do
      let!(:auth_settings) { create(:auth_setting, organization: organization) }

      context "when the email_auth_settings is disabled" do
        it "renders the :sms template" do
          get :email
          expect(response).to redirect_to("/")
          expect(flash[:error]).to eq("You are not allowed to perform this action.")
        end
      end

      context "when the email_auth settings is enabled" do
        before do
          auth_settings.enable_partial_email_signup = true
          auth_settings.save
        end

        it "renders the :email template" do
          get :email
          expect(response).to render_template(:email)
        end
      end
    end

    context "when user is authorized" do
      before { sign_in user }

      it "redirects to root path" do
        get :email
        expect(response).to redirect_to("/")
      end
    end
  end

  describe "POST #verification" do
    context "when auth method is SMS" do
      let!(:method) { "sms" }

      before do
        allow(SecureRandom).to receive(:random_number).and_return("1234")
      end

      it "sends a verification code and redirects to verify action" do
        post :verification, params: { auth_method: "sms", phone_number: "457787874", phone_country: "FI", organization: organization }

        expect(auth_session).to include("method" => "sms", "code" => "1234", "country" => "FI", "phone" => 4_577_878_74)
        expect(response).to redirect_to(action: "verify")
      end

      it "renders the sms template when verification fails" do
        post :verification, params: { auth_method: "sms", phone_number: "", phone_country: "FI" }

        expect(flash[:alert]).to be_present
        expect(response).to render_template(:sms)
      end
    end

    context "when auth method is email" do
      let!(:method) { "email" }

      before do
        allow(SecureRandom).to receive(:random_number).and_return("1234")
      end

      it "sends a verification code and redirects to verify action" do
        post :verification, params: { auth_method: "email", email: "someone@example.com" }

        expect(auth_session).to include("method" => "email", "code" => "1234", "email" => "someone@example.com")
        expect(response).to redirect_to(action: "verify")
      end

      it "renders the sms template when verification fails" do
        post :verification, params: { auth_method: "email", email: "" }

        expect(flash[:alert]).to be_present
        expect(response).to render_template(:email)
      end
    end
  end

  describe "GET #verify" do
    let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_sms_signup: true) }
    let!(:method) { "sms" }
    let!(:country) { "FI" }
    let!(:phone) { 4_576_776_517 }

    it "renders the :verify template" do
      get :verify
      expect(response).to render_template(:verify)
    end

    context "when the auth session is not available" do
      let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_sms_signup: true, enable_partial_email_signup: true) }
      let(:auth_session) { nil }

      it "redirects to the options view" do
        get :verify
        expect(response).to redirect_to(action: "options")
      end
    end
  end

  describe "POST #authenticate" do
    context "when sms auth" do
      let!(:method) { "sms" }
      let!(:phone) { "123456789" }
      let!(:country) { "FI" }

      context "when correct" do
        context "when account does not exist" do
          it "creates the account and authenticates user" do
            expect do
              post :authenticate, params: { verification_code: { verification: correct_code } }
            end.to change(Decidim::User, :count).by(1)
            user = Decidim::User.last
            expect(user.phone_number).to eq("123456789")
            expect(user.phone_country).to eq("FI")
            expect(user.email).to match(/^quick_auth-\w*@#{organization.host}$/)
            expect(response).to redirect_to("/authorizations")
            expect(request.session[:auth_attempt]).to be_nil
          end
        end

        context "when user exists" do
          before do
            create(:user, :confirmed, organization: organization, phone_number: "123456789", phone_country: "FI", email: "someone@example.org")
          end

          it "authenticates and logs in" do
            expect do
              post :authenticate, params: { verification_code: { verification: correct_code } }
            end.not_to change(Decidim::User, :count)
            expect(response).to redirect_to("/authorizations")
          end
        end
      end

      context "when incorrect" do
        it "does not authenticate" do
          post :authenticate, params: { verification_code: { verification: wrong_code } }
          expect(response).to render_template(:verify)
          expect(flash[:error]).to eq("Verification failed. Please try again.")
        end
      end
    end

    context "when email auth" do
      let!(:method) { "email" }
      let!(:email) { "someone@example.org" }

      context "when correct" do
        context "when account does not exist" do
          it "creates the account and authenticates user" do
            expect do
              post :authenticate, params: { verification_code: { verification: correct_code } }
            end.to change(Decidim::User, :count).by(1)
            user = Decidim::User.last
            expect(user.phone_number).to be_nil
            expect(user.phone_country).to be_nil
            expect(user.email).to eq("someone@example.org")
            expect(response).to redirect_to("/authorizations")
            expect(request.session[:auth_attempt]).to be_nil
          end
        end

        context "when user exists" do
          before do
            create(:user, :confirmed, organization: organization, email: "someone@example.org")
          end

          it "authenticates and logs in" do
            expect do
              post :authenticate, params: { verification_code: { verification: correct_code } }
            end.not_to change(Decidim::User, :count)
            expect(response).to redirect_to("/authorizations")
          end
        end
      end

      context "when incorrect" do
        it "does not authenticate" do
          post :authenticate, params: { verification_code: { verification: wrong_code } }
          expect(response).to render_template(:verify)
          expect(flash[:error]).to eq("Verification failed. Please try again.")
        end
      end
    end

    context "when too many failing attempts" do
      let!(:attempts) { 20 }

      context "when less than two minutes has passed since last attempt" do
        let!(:last_attempt) { 1.minute.ago }

        it "redirects the user to the verify and displays error message" do
          post :authenticate, params: { verification_code: { verification: correct_code } }
          expect(response).to redirect_to(action: "verify")
          expect(flash[:error]).to eq("Too many failed attempts. Please try again later.")
          expect(auth_session).to include("attempts" => 20)
        end
      end
    end
  end

  describe "GET #resend" do
    context "when sms auth" do
      let!(:method) { "sms" }
      let!(:phone) { "457832145" }
      let!(:country) { "FI" }

      context "when resend allowed" do
        before do
          auth_session["sent_at"] = 2.minutes.ago
        end

        it "resends the code and redirexts the user" do
          get :resend
          expect(response).to redirect_to(action: "verify")
          expect(flash[:notice]).to eq("Verification code sent to +358457832145.")
        end
      end

      context "when not allowed" do
        it "does not send code" do
          get :resend
          expect(response).to redirect_to(action: "verify")
          expect(flash[:error]).to eq("Please wait at least 1 minute to resend the code.")
        end
      end
    end

    context "when email auth" do
      let!(:method) { "email" }
      let!(:email) { "some_email@example.com" }

      it "always resends the code" do
        get :resend
        expect(response).to redirect_to(action: "verify")
        expect(flash[:notice]).to eq("Verification code sent to some_email@example.com.")
      end
    end
  end
end
