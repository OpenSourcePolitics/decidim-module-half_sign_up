# frozen_string_literal: true

require "spec_helper"

describe "Admin manage auth settings", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:admin) { create(:user, :admin, :confirmed, organization: organization) }
  let(:auth_settings) { create(:auth_setting, organization: organization) }
  let(:decidim_half_signup_admin) { Decidim::HalfSignup::AdminEngine.routes.url_helpers }

  before do
    sign_in admin
    switch_to_host(organization.host)
    visit decidim_admin.edit_organization_path
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
    check "Enable partial sms signup"
    click_button "Update"
    expect(page).to have_current_path(decidim_half_signup_admin.edit_auth_setting_path(slug: "authentication_settings"))
    within ".callout-wrapper" do
      expect(page).to have_content("Organization updated successfully.")
    end
    expect(page.find("#auth_setting_enable_partial_sms_signup")).to be_checked
    auth_settings = Decidim::HalfSignup::AuthSetting.last
    expect(auth_settings.enable_partial_email_signup).to be(false)
    expect(auth_settings.enable_partial_sms_signup).to be(true)
  end
end
