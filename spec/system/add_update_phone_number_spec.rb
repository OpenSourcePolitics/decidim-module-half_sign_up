# frozen_string_literal: true

require "spec_helper"

describe "Add/update phone number", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let!(:auth_settings) { create(:auth_setting, organization: organization) }
  let(:decidim_half_signup_admin) { Decidim::HalfSignup::AdminEngine.routes.url_helpers }
  let(:sms_gateway_service) { "Decidim::Verifications::Sms::ExampleGateway" }
  let(:phone) { "4578878784" }

  before do
    sign_in user
    switch_to_host(organization.host)
    visit decidim.account_path

    Decidim.configure do |config|
      config.sms_gateway_service = sms_gateway_service
    end
  end

  context "when sms_auth is not enabled" do
    it "does not show the link to update/add phone" do
      expect(page).to have_current_path("/account")
      expect(page).not_to have_link("Add your phone number")
      expect(page).not_to have_link("Update your phone number")
      expect(page).not_to have_content("Mask number")
    end
  end

  context "when auth_settings is enabled sms" do
    before do
      auth_settings.update!(enable_partial_sms_signup: true)
      visit current_path
    end

    context "when user has not added their phone number" do
      it "shows the link to add their phone number" do
        expect(page).to have_current_path("/account")
        expect(page).to have_link("Add your phone number")
      end
    end

    context "when they have already added a phone number" do
      before do
        user.update!(phone_number: "4578878784", phone_country: "FI")
        visit current_path
      end

      it "shows the path to update" do
        expect(page).to have_current_path("/account")
        expect(page).to have_link("Update your phone number")
        field = find_field("user[mask_number]", disabled: true)
        expect(field[:disabled]).to be_truthy
        expect(field.value).to eq("+358*****784")
      end
    end

    describe "#update phone" do
      before do
        auth_settings.update!(enable_partial_sms_signup: true)
        visit current_path
      end

      it "update the phone number" do
        expect(page).to have_link("Add your phone number")
        click_link "Add your phone number"
        find("span.arrow-down").click
        within ".ss-list" do
          find("div", text: /Finland/).select_option
        end
        fill_in "Phone number", with: phone
        click_button "Send the code"
        code = page.find("#hint").text
        fill_in_code(code, "digit")
        click_button "Verify"
        expect(page).to have_current_path("/account")
        within_flash_messages do
          expect(page).to have_content("User account updated successfully.")
        end
        expect(page).to have_link("Update your phone number")
        field = find_field("user[mask_number]", disabled: true)
        expect(field[:disabled]).to be_truthy
        expect(field.value).to eq("+358*****784")
      end

      context "when phone number is registered previously" do
        let!(:second_user) { create(:user, :confirmed, organization: organization, phone_number: "4578878784", phone_country: "FI") }

        before do
          click_link "Add your phone number"
          find("span.arrow-down").click
          within ".ss-list" do
            find("div", text: /Finland/).select_option
          end
          fill_in "Phone number", with: phone
          click_button "Send the code"
          code = page.find("#hint").text
          fill_in_code(code, "digit")
          click_button "Verify"
        end

        it "redirects the user with a message" do
          expect(page).to have_current_path("/users/quick_auth/update_phone")
          within_flash_messages do
            expect(page).to have_content("This phone number is bined to another account. Please use another phone number, or contact administration")
          end
        end
      end
    end
  end

  private

  def fill_in_code(code, element)
    code.length.times do |ind|
      fill_in "#{element}#{ind + 1}", with: code[ind]
    end
  end
end
