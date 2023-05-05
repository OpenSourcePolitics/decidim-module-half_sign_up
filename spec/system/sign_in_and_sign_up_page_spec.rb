# frozen_string_literal: true

require "spec_helper"

describe "Sign in and sign up page", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:admin) { create(:user, :admin, :confirmed, organization: organization) }
  let!(:auth_settings) { create(:auth_setting, organization: organization) }
  let(:decidim_half_signup) { Decidim::HalfSignup::Engine.routes.url_helpers }

  describe "login" do
    before do
      switch_to_host(organization.host)
      visit decidim.root_path
    end

    context "when auth_settings is not enabled" do
      before do
        click_link "Sign In"
      end

      it "redirects to normal login page" do
        expect(page).to have_current_path decidim.user_session_path
        expect(page).to have_content("Email")
        expect(page).to have_content("Password")
        expect(page).to have_button("Log in")
      end
    end

    context "when modal login pops up" do
      let(:decidim_budgets) { Decidim::EngineRouter.main_proxy(component) }
      let!(:component) { create(:budgets_component, organization: organization) }
      let!(:budget) { create(:budget, component: component) }
      let!(:projects) { create_list(:project, 3, budget: budget) }

      context "when no auth_setting is enabled" do
        before do
          click_a_project
        end

        it "popups with normal decidim layout" do
          expect(page).to have_css("#loginModal")
          within "#loginModal" do
            expect(page).to have_field("Email")
            expect(page).to have_field("Password")
            expect(page).to have_button("Log in")
          end
        end
      end

      context "when email auth is enabled" do
        before do
          auth_settings.update!(enable_partial_email_signup: true)
          click_a_project
        end

        it "shows email link in the popup" do
          expect(page).to have_css("#loginModal")
          within "#loginModal" do
            expect(page).to have_no_content("Please select how you would like to sign in.")
            expect(page).to have_content("Please sign in")
            expect(page).to have_link("With your email", href: "/users/quick_auth/email")
            expect(page).to have_no_link("With your phone")
          end
        end
      end

      context "when sms auth is enabled" do
        before do
          auth_settings.update!(enable_partial_sms_signup: true)
          click_a_project
        end

        it "shows email link in the popup" do
          expect(page).to have_css("#loginModal")
          within "#loginModal" do
            expect(page).to have_no_content("Please select how you would like to sign in.")
            expect(page).to have_content("Please sign in")
            expect(page).to have_link("With your phone", href: "/users/quick_auth/sms")
            expect(page).to have_no_link("With your email")
          end
        end
      end

      context "when both are enalbed" do
        before do
          auth_settings.update!(enable_partial_sms_signup: true, enable_partial_email_signup: true)
          click_a_project
        end

        it "shows email link in the popup" do
          expect(page).to have_css("#loginModal")
          within "#loginModal" do
            expect(page).to have_content("Please select how you would like to sign in.")
            expect(page).to have_content("Please sign in")
            expect(page).to have_link("With your phone", href: "/users/quick_auth/sms")
            expect(page).to have_link("With your email", href: "/users/quick_auth/email")
          end
        end
      end
    end

    context "when email settings are enabled" do
      let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_email_signup: true) }

      before do
        click_link "Sign In"
      end

      it "redirects the user to the quick_auth email_path" do
        expect(page).to have_current_path(decidim_half_signup.users_quick_auth_email_path)
        expect(page).to have_button("Send the code")
        expect(page).to have_content("Please enter your email:")
      end
    end
  end

  describe "Signup" do
    before do
      switch_to_host(organization.host)
      visit decidim.root_path
    end

    context "when auth_settings is not enabled" do
      before do
        click_link "Sign Up"
      end

      it "redirects to normal sign up page" do
        expect(page).to have_current_path decidim.new_user_registration_path
        expect(page).to have_content("Sign up")
        expect(page).to have_content("Terms of Service")
        expect(page).to have_button("Sign up")
      end
    end

    context "when sms settings are enabled" do
      let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_sms_signup: true) }

      before do
        click_link "Sign Up"
      end

      it "redirects the user to the quick_auth_sms_path" do
        expect(page).to have_current_path(decidim_half_signup.users_quick_auth_sms_path)
        expect(page).to have_button("Send the code")
        expect(page).to have_content("Please enter your phone number:")
      end
    end

    context "when both sms and email is enabled" do
      let!(:auth_settings) do
        create(
          :auth_setting,
          organization: organization,
          enable_partial_sms_signup: true,
          enable_partial_email_signup: true
        )
      end

      before do
        click_link "Sign Up"
      end

      it "redirects the user to the quick_auth_path" do
        expect(page).to have_current_path(decidim_half_signup.users_quick_auth_path)
        expect(page).to have_link("To your phone")
        expect(page).to have_link("To your email")
      end
    end
  end

  private

  def click_a_project
    visit decidim_budgets.budget_projects_path(budget.id)
    button = find("#project-vote-button-#{projects.first.id}")
    page.execute_script("arguments[0].removeAttribute('disabled')", button)
    button.click
  end
end
