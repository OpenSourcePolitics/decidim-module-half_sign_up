# frozen_string_literal: true

require "spec_helper"

describe "Manage sms sign in", type: :system do
  let(:organization) { create(:organization) }
  let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_sms_signup: true) }
  let(:decidim_half_signup) { Decidim::HalfSignup::Engine.routes.url_helpers }

  before do
    allow(Decidim::HalfSignup.config).to receive(:default_countries).and_return([])
    switch_to_host(organization.host)
    visit decidim.root_path
  end

  describe "Sign in/Sign up process" do
    let(:phone) { 4_551_122_334 }
    let(:phone_country) { "FI" }

    before do
      click_link "Sign In"
    end

    context "when the account does not exist" do
      context "when enter phone number" do
        before { click_link "TO YOUR PHONE" }

        it "selects the country and enters the phone number" do
          expect(page).to have_current_path(decidim_half_signup.users_quick_auth_sms_path)
          find("span.arrow-down").click
          within ".ss-list" do
            find("div", text: /Finland/).select_option
          end
          click_button "Send code via SMS"
          expect(page).to have_content "There's an error in this field."
          fill_in "Phone number", with: phone
          click_button "Send code via SMS"
          expect(page).to have_current_path(decidim_half_signup.users_quick_auth_verify_path)
        end
      end

      context "when verify" do
        before do
          click_link "TO YOUR PHONE"
          find("span.arrow-down").click
          within ".ss-list" do
            find("div", text: /Finland/).select_option
          end
          fill_in "Phone number", with: phone
          click_button "Send code via SMS"
        end

        it "renders the verify page" do
          expect(page).to have_current_path(decidim_half_signup.users_quick_auth_verify_path)
          expect(page).to have_content("The verificaiton code is")
          within ".flash" do
            expect(page).to have_content("Verification code sent to +3584551122334.")
          end
          click_link "Resend code"
          within ".flash" do
            expect(page).to have_content("Please wait at least 1 minute to resend the code.")
          end
          expect(page).to have_link("use another method", href: decidim_half_signup.users_quick_auth_path)
          code = page.find("#hint").text
          fill_in "Verification", with: code
          click_button "Verify"
          expect(page).to have_content "Agree to the terms and conditions of use"
          click_button "I agree with these terms"
          expect(page).to have_current_path("/authorizations")
          expect(Decidim::User.count).to eq(1)
          user = Decidim::User.last
          expect(user.name).to eq("Unnamed user")
          expect(user.phone_country).to eq("FI")
          expect(user.phone_number).to eq("4551122334")
        end
      end
    end

    context "when the account exists" do
      let!(:user) { create(:user, :confirmed, organization: organization, phone_number: "4551122334", phone_country: "FI") }

      before do
        click_link "TO YOUR PHONE"
        find("span.arrow-down").click
        within ".ss-list" do
          find("div", text: /Finland/).select_option
        end
        fill_in "Phone number", with: phone
        click_button "Send code via SMS"
        code = page.find("#hint").text
        fill_in "Verification", with: code
        click_button "Verify"
      end

      it "logs in the user and redirects it" do
        expect(page).to have_current_path("/authorizations")
        expect(Decidim::User.count).to eq(1)
        expect(Decidim::User.last).to eq(user)
      end
    end
  end
end
