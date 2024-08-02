# frozen_string_literal: true

require "spec_helper"

describe "Admin manage auth settings", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:admin) { create(:user, :admin, :confirmed, organization: organization) }
  let(:auth_settings) { create(:auth_setting, organization: organization) }
  let(:decidim_half_signup_admin) { Decidim::HalfSignup::AdminEngine.routes.url_helpers }
  let(:sms_gateway_service) { "Decidim::Verifications::Sms::ExampleGateway" }

  before do
    sign_in admin
    switch_to_host(organization.host)
    visit decidim_admin.edit_organization_path

    allow(Decidim.config).to receive(:sms_gateway_service).and_return(sms_gateway_service)
  end

  after do
    allow(Decidim.config).to receive(:sms_gateway_service).and_call_original
  end

  it "shows the menu in the admin panel in a correct place" do
    expect(page).to have_link("Authentication settings", href: decidim_half_signup_admin.edit_auth_setting_path(slug: "authentication_settings"))
    # checking the order of items in the navbar
    expect(page).to have_css(".is-active", text: "Configuration")
    els = find_all(".secondary-nav ul li")
    expect(els[0]).to have_content("Configuration")
    expect(els[1]).to have_content("Authentication settings")
  end

  it "updates the auth settings" do
    click_link "Authentication settings"
    expect(page).to have_current_path(decidim_half_signup_admin.edit_auth_setting_path(slug: "authentication_settings"))
    expect(page).to have_css(".is-active", text: "Authentication settings")
    # default should be unchecked
    options = all("input[type=checkbox]")
    options.each do |option|
      expect(option).not_to be_checked
    end
    check "Enable partial sign up and sign in using SMS verification"
    click_button "Update"
    expect(page).to have_current_path(decidim_half_signup_admin.edit_auth_setting_path(slug: "authentication_settings"))
    within ".callout-wrapper" do
      expect(page).to have_content("Organization updated successfully.")
    end
    expect(page).to have_content("Settings available through code")
    within "code" do
      expect(page).to have_content("Decidim::HalfSignup.configure do |config|")
    end
    expect(page.find("#auth_setting_enable_partial_sms_signup")).to be_checked
    auth_settings = Decidim::HalfSignup::AuthSetting.last
    expect(auth_settings.enable_partial_email_signup).to be(false)
    expect(auth_settings.enable_partial_sms_signup).to be(true)
  end

  context "when sms gateway service is not present" do
    before do
      allow(Decidim.config).to receive(:sms_gateway_service).and_return(nil)
    end

    it "shows a warning message when the SMS gateway service is not configured" do
      click_link "Authentication settings"
      expect(page).to have_current_path(decidim_half_signup_admin.edit_auth_setting_path(slug: "authentication_settings"))
      expect(page).to have_css(".is-active", text: "Authentication settings")
      expect(page.find("#auth_setting_enable_partial_sms_signup")).to be_disabled
      expect(page).to have_content("This option is disabled please contact the host of the platform to enable it.")
    end

    it "shows an error message when the SMS gateway service is not configured if the user tries to force the change" do
      click_link "Authentication settings"
      expect(page).to have_current_path(decidim_half_signup_admin.edit_auth_setting_path(slug: "authentication_settings"))
      expect(page).to have_css(".is-active", text: "Authentication settings")
      check "Enable partial sign up and sign in using SMS verification"
      check "Enable partial sign up and sign in using email verification"

      allow(Decidim.config).to receive(:sms_gateway_service).and_return(nil)

      click_button "Update"
      expect(page).to have_current_path(decidim_half_signup_admin.edit_auth_setting_path(slug: "authentication_settings"))
      within ".callout-wrapper" do
        expect(page).not_to have_content("Organization updated successfully.")
        expect(page).to have_content("The SMS gateway service is not defined.")
      end
      expect(page).to have_content("Settings available through code")
      within "code" do
        expect(page).to have_content("Decidim::HalfSignup.configure do |config|")
      end
      expect(page.find("#auth_setting_enable_partial_sms_signup")).not_to be_checked
      auth_settings = Decidim::HalfSignup::AuthSetting.last
      expect(auth_settings.enable_partial_email_signup).to be(false)
      expect(auth_settings.enable_partial_sms_signup).to be(false)
    end
  end
end
