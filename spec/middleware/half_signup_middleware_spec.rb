# frozen_string_literal: true

require "spec_helper"

RSpec.describe HalfSignupMiddleware do
  let(:app) { ->(_env) { [200, {}, ["Hello, world!"]] } }
  let(:middleware) { HalfSignupMiddleware.new(app) }
  let(:user) { create(:user, email: email, name: name) }
  let(:email) { "quick_auth@example.com" }
  let(:name) { "Anonymous user" }

  def session_double(key)
    { "warden.user.user.key" => [key, nil] }
  end

  def env_with_path(path, query_string = "")
    { "REQUEST_METHOD" => "GET", "PATH_INFO" => path, "QUERY_STRING" => query_string, "rack.session" => {} }
  end

  describe "#call" do
    context "when user is half signup user" do
      let(:env) { env_with_path("/some_path") }

      before do
        allow_any_instance_of(Rack::Request).to receive(:session).and_return(session_double([user.id, nil]))
      end

      it "handles half signup request" do
        expect(middleware).to receive(:handle_half_signup_request).with(env)
        middleware.call(env)
      end
    end

    context "when user is not half signup user" do
      let(:email) { "user@example.com" }
      let(:env) { env_with_path("/some_path") }

      before do
        allow_any_instance_of(Rack::Request).to receive(:session).and_return(session_double([user.id, nil]))
        allow(Decidim::User).to receive(:find).and_return(user)
      end

      it "does not handle half signup request" do
        expect(middleware).not_to receive(:handle_half_signup_request)
        middleware.call(env)
      end
    end

    context "when user is not found" do
      let(:env) { env_with_path("/some_path") }

      before do
        allow_any_instance_of(Rack::Request).to receive(:session).and_return(session_double([999, nil]))
      end

      it "does not handle half signup request" do
        expect(middleware).not_to receive(:handle_half_signup_request)
        middleware.call(env)
      end
    end
  end

  describe "#handle_half_signup_request" do
    context "when path is allowed" do
      let(:env) { env_with_path("/quick_auth") }

      it "calls the next middleware" do
        expect(app).to receive(:call).with(env)
        middleware.send(:handle_half_signup_request, env)
      end

      context "and path is in query string" do
        let(:env) { env_with_path("/invalid", "some_param=/quick_auth") }

        it "signs out" do
          expect(middleware).to receive(:sign_out_user).at_least(:once)
          expect(app).to receive(:call).with(env)
          middleware.send(:handle_half_signup_request, env)
        end
      end
    end

    context "when path is not allowed" do
      context "when path is a voting or order page" do
        let(:env) { env_with_path("/budgets/123/voting") }

        it "calls the next middleware" do
          expect(app).to receive(:call).with(env)
          middleware.send(:handle_half_signup_request, env)
        end
      end

      context "when path is neither voting nor order page" do
        let(:env) { env_with_path("/some_path") }

        it "signs out user and calls the next middleware" do
          expect(middleware).to receive(:sign_out_user)
          expect(app).to receive(:call).with(env)
          middleware.send(:handle_half_signup_request, env)
        end
      end
    end
  end
end