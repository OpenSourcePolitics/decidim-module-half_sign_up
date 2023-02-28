# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::HalfSignup::QuickAuthController, type: :controller do
  routes { Decidim::HalfSignup::Engine.routes }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:organization) { create(:organization) }
  let(:decidim_half_signup) { Decidim::HalfSignup::Engine.routes.url_helpers }

  before do
    request.env["decidim.current_organization"] = organization
    request.env["devise.mapping"] = ::Devise.mappings[:user]
  end

  describe "GET #sms" do
    context "when user is not authorized" do
      let!(:auth_settings) { create(:auth_setting, organization: organization) }

      context "when the sms_auth_settings is disabled" do
        it "renders the :sms template" do
          get :sms
          expect(response).to redirect_to(decidim_half_signup.users_quick_auth_path)
        end
      end

      context "when the sams_auth settings is enabled" do
        before do
          auth_settings.enable_partial_sms_signup = true
          auth_settings.save
        end

        it "renders the :sms template" do
          get :sms
          expect(response).to render_template(:sms)
        end
      end
    end

    context "when user is authorized" do
      before { sign_in user }

      it "redirects to root path" do
        get :sms
        expect(response).to redirect_to("/")
      end
    end
  end

  describe "GET #email" do
    context "when user is not authorized" do
      let!(:auth_settings) { create(:auth_setting, organization: organization) }

      context "when the email_auth_settings is disabled" do
        it "renders the :sms template" do
          get :sms
          expect(response).to redirect_to(decidim_half_signup.users_quick_auth_path)
        end
      end

      context "when the email_auth settings is enabled" do
        before do
          auth_settings.enable_partial_sms_signup = true
          auth_settings.save
        end

        it "renders the :email template" do
          get :sms
          expect(response).to render_template(:sms)
        end
      end
    end

    context "when user is authorized" do
      before { sign_in user }

      it "redirects to root path" do
        get :sms
        expect(response).to redirect_to("/")
      end
    end
  end

  describe "POST #verification" do
    let!(:auth_session) do
      {
        "code" => nil,
        "country" => nil,
        "phone" => nil,
        "email" => nil,
        "method" => nil,
        "verified" => false,
        "sent_at" => Time.current
      }
    end

    context "when auth method is SMS" do
      before do
        auth_session["method"] = "sms"
        allow(SecureRandom).to receive(:random_number).and_return("123456")
        request.session[:auth_attempt] = auth_session
      end

      it "sends a verification code and redirects to verify action" do
        post :verification, params: { auth_method: "sms", phone_number: "457787874", phone_country: "FI" }

        expect(auth_session).to include("method" => "sms", "code" => "123456", "country" => "FI", "phone" => 4_577_878_74)
        expect(response).to redirect_to(action: "verify")
      end

      it "renders the sms template when verification fails" do
        post :verification, params: { auth_method: "sms", phone_number: "", phone_country: "FI" }

        expect(flash[:alert]).to be_present
        expect(response).to render_template(:sms)
      end
    end

    context "when auth method is email" do
      before do
        auth_session["method"] = "email"
        allow(SecureRandom).to receive(:random_number).and_return("123456")
        request.session[:auth_attempt] = auth_session
      end

      it "sends a verification code and redirects to verify action" do
        post :verification, params: { auth_method: "email", email: "someone@example.com" }

        expect(auth_session).to include("method" => "email", "code" => "123456", "email" => "someone@example.com")
        expect(response).to redirect_to(action: "verify")
      end

      it "renders the sms template when verification fails" do
        post :verification, params: { auth_method: "email", email: "" }

        expect(flash[:alert]).to be_present
        expect(response).to render_template(:email)
      end
    end
  end

  describe "GET#verify" do
    let!(:auth_session) do
      { "code" => "123456" }
    end

    before do
      request.session[:auth_attempt] = auth_session
    end

    it "renders the :verify template" do
      get :verify
      expect(response).to render_template(:verify)
    end
  end

  describe "POST#authenticate" do
    let!(:auth_session) do
      {
        "code" => nil,
        "country" => nil,
        "phone" => nil,
        "email" => nil,
        "method" => nil,
        "verified" => false,
        "sent_at" => Time.current
      }
    end

    before do
      request.session[:auth_attempt] = auth_session
    end

    context "when sms auth" do
      let(:correct_code) { "correct code" }
      let(:wrong_code) { "wrong code" }

      before do
        auth_session["method"] = "sms"
        auth_session["phone"] = "123456789"
        auth_session["country"] = "FI"
        auth_session["code"] = correct_code
      end

      context "when correct" do
        let!(:code) { correct_code }

        context "when account does not exist" do
          it "creates the account and authenticates user" do
            expect do
              post :authenticate, params: { verification_code: { verification: code } }
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
              post :authenticate, params: { verification_code: { verification: code } }
            end.not_to change(Decidim::User, :count)
            expect(response).to redirect_to("/authorizations")
          end
        end
      end

      context "when incorrect" do
        let!(:code) { wrong_code }

        it "does not authenticate" do
          post :authenticate, params: { verification_code: { verification: code } }
          expect(response).to render_template(:verify)
          expect(flash[:error]).to eq("Verification failed. Please try again.")
        end
      end
    end

    context "when email auth" do
      let(:correct_code) { "correct code" }
      let(:wrong_code) { "wrong code" }

      before do
        auth_session["method"] = "email"
        auth_session["email"] = "someone@example.org"
        auth_session["code"] = correct_code
      end

      context "when correct" do
        let!(:code) { correct_code }

        context "when account does not exist" do
          it "creates the account and authenticates user" do
            expect do
              post :authenticate, params: { verification_code: { verification: code } }
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
              post :authenticate, params: { verification_code: { verification: code } }
            end.not_to change(Decidim::User, :count)
            expect(response).to redirect_to("/authorizations")
          end
        end
      end

      context "when incorrect" do
        let!(:code) { wrong_code }

        it "does not authenticate" do
          post :authenticate, params: { verification_code: { verification: code } }
          expect(response).to render_template(:verify)
          expect(flash[:error]).to eq("Verification failed. Please try again.")
        end
      end
    end
  end

  describe "Get#resend" do
    let!(:auth_session) do
      {
        "code" => "123456",
        "country" => nil,
        "phone" => nil,
        "email" => nil,
        "method" => nil,
        "verified" => false,
        "sent_at" => Time.current
      }
    end

    context "when sms auth" do
      before do
        auth_session["method"] = "sms"
        auth_session["phone"] = "457832145"
        auth_session["country"] = "FI"
        request.session[:auth_attempt] = auth_session
      end

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
      before do
        auth_session["method"] = "email"
        auth_session["email"] = "some_email@example.com"
        request.session[:auth_attempt] = auth_session
      end

      it "always resends the code" do
        get :resend
        expect(response).to redirect_to(action: "verify")
        expect(flash[:notice]).to eq("Verification code sent to some_email@example.com.")
      end
    end
  end
end
