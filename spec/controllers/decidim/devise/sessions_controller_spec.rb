# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Devise
    describe SessionsController, type: :controller do
      routes { Decidim::Core::Engine.routes }
      let!(:organization) { create(:organization) }

      before do
        request.env["decidim.current_organization"] = organization
        request.env["devise.mapping"] = ::Devise.mappings[:user]
      end

      context "when half signup is disabled" do
        # half_signup is disabled by default
        let!(:auth_settings) { create(:auth_setting, organization: organization) }

        it "redirects user to the auick_auth path" do
          get :new
          expect(response).to have_http_status(:ok)
          expect(subject).to render_template("decidim/devise/sessions/new")
        end
      end

      context "when half signup is enabled" do
        # half_signup is disabled by default
        let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_sms_signup: true) }

        it "redirects user to the auick_auth path" do
          get :new
          expect(response).to redirect_to(decidim_half_signup.users_quick_auth_path)
        end
      end

      private

      def decidim_half_signup
        Decidim::HalfSignup::Engine.routes.url_helpers
      end
    end
  end
end
