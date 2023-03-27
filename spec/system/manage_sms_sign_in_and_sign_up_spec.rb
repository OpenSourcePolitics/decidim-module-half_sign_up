# frozen_string_literal: true

require "spec_helper"

describe "Manage sms sign in", type: :system do
  let(:organization) { create(:organization) }
  let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_sms_signup: true) }
  let(:decidim_half_signup) { Decidim::HalfSignup::Engine.routes.url_helpers }
  let(:phone) { 4_551_122_334 }
  let(:phone_country) { "FI" }

  before do
    allow(Decidim::HalfSignup.config).to receive(:default_countries).and_return([])
    switch_to_host(organization.host)
    visit decidim.root_path
  end

  describe "Sign in/Sign up process" do
    before do
      click_link "Sign In"
    end

    context "when the account does not exist" do
      context "when enter phone number" do
        it "selects the country and enters the phone number" do
          expect(page).to have_current_path(decidim_half_signup.users_quick_auth_sms_path)
          find("span.arrow-down").click
          within ".ss-list" do
            find("div", text: /Finland/).select_option
          end
          click_button "SEND THE CODE"
          expect(page).to have_content "There's an error in this field."
          fill_in "Phone number", with: phone
          click_button "SEND THE CODE"
          expect(page).to have_current_path(decidim_half_signup.users_quick_auth_verify_path)
        end
      end

      context "when verify" do
        before do
          find("span.arrow-down").click
          within ".ss-list" do
            find("div", text: /Finland/).select_option
          end
          fill_in "Phone number", with: phone
          click_button "SEND THE CODE"
        end

        it "renders the verify page" do
          expect(page).to have_current_path(decidim_half_signup.users_quick_auth_verify_path)
          expect(page).to have_content("The verificaiton code is")
          within ".flash" do
            expect(page).to have_content("Verification code sent to +3584551122334.")
          end
          click_link "Send it again."
          within ".flash" do
            expect(page).to have_content("Please wait at least 1 minute to resend the code.")
          end
          code = page.find("#hint").text
          fill_in_code(code, "digit")
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
        find("span.arrow-down").click
        within ".ss-list" do
          find("div", text: /Finland/).select_option
        end
        fill_in "Phone number", with: phone
        click_button "SEND THE CODE"
        code = page.find("#hint").text
        fill_in_code(code, "digit")
        click_button "Verify"
      end

      it "logs in the user and redirects it" do
        expect(page).to have_current_path("/authorizations")
        expect(Decidim::User.count).to eq(1)
        expect(Decidim::User.last).to eq(user)
      end
    end
  end

  context "when both email and sms method is enabled" do
    before do
      auth_settings.update(enable_partial_email_signup: true)
      click_link "Sign In"
    end

    it "renders the select page" do
      expect(page).to have_current_path(decidim_half_signup.users_quick_auth_path)
      click_link "TO YOUR PHONE"
      expect(page).to have_content("Use Another method")
      find("span.arrow-down").click
      within ".ss-list" do
        find("div", text: /Finland/).select_option
      end
      fill_in "Phone number", with: phone
      click_button "SEND THE CODE"
      expect(page).to have_content("incorrect phone number?")
      click_link "(incorrect phone number?)"
      expect(page).to have_current_path(decidim_half_signup.users_quick_auth_sms_path)
    end
  end

  context "when auth length code is not default" do
    before do
      allow(Decidim::HalfSignup).to receive(:auth_code_length).and_return(5)
      click_link "Sign In"
      find("span.arrow-down").click
      within ".ss-list" do
        find("div", text: /Finland/).select_option
      end
      fill_in "Phone number", with: phone
      click_button "SEND THE CODE"
    end

    it "renders 5 input field and send 5 digit code" do
      expect(page.find_all("input[name^='digit']").count).to eq(5)
      code = page.find("#hint").text
      expect(code.length).to eq(5)
    end
  end

  context "when set not to show tos agreement" do
    before do
      allow(Decidim::HalfSignup).to receive(:show_tos_page_after_signup).and_return(false)
      click_link "Sign In"
      find("span.arrow-down").click
      within ".ss-list" do
        find("div", text: /Finland/).select_option
      end
      fill_in "Phone number", with: phone
      click_button "SEND THE CODE"
      code = page.find("#hint").text
      fill_in_code(code, "digit")
      click_button "Verify"
    end

    it "does not show the tos agreement" do
      expect(page).to have_current_path("/authorizations")
      expect(page).not_to have_content "Agree to the terms and conditions of use"
    end
  end

  private

  def fill_in_code(code, element)
    code.length.times do |ind|
      fill_in "#{element}#{ind + 1}", with: code[ind]
    end
  end
end
