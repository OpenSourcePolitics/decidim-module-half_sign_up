# frozen_string_literal: true

require "spec_helper"

describe "Manage sms sign in", type: :system do
  let(:organization) { create(:organization) }
  let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_email_signup: true) }
  let(:decidim_half_signup) { Decidim::HalfSignup::Engine.routes.url_helpers }
  let(:email) { "someone@example.org" }
  let!(:user) { create(:user, :confirmed, email: "anotherone@example.org", organization: auth_settings.organization) }
  let(:code) { "1234" }

  before do
    switch_to_host(organization.host)
    visit decidim.root_path
  end

  describe "Sign in/Sign up process" do
    before do
      click_link "Sign In"
    end

    context "when the account does not exist" do
      before do
        allow(SecureRandom).to receive(:random_number).and_return(code)
      end

      context "when enter email" do
        it "enters the email" do
          expect(page).to have_current_path(decidim_half_signup.users_quick_auth_email_path)
          click_button "SEND THE CODE"
          expect(page).to have_content "There's an error in this field."
          fill_in "Email", with: email
          click_button "SEND THE CODE"
          expect(page).to have_current_path(decidim_half_signup.users_quick_auth_verify_path)
        end
      end

      context "when verify" do
        before do
          fill_in "Email", with: email
          click_button "SEND THE CODE"
        end

        it "renders the verify page" do
          expect(page).to have_current_path(decidim_half_signup.users_quick_auth_verify_path)
          within ".flash" do
            expect(page).to have_content("Verification code sent to someone@example.org.")
          end
          click_link "Send it again."
          within ".flash" do
            expect(page).not_to have_content("Please wait at least 1 minute to resend the code.")
            expect(page).to have_content("Verification code sent to someone@example.org.")
          end
          fill_in_code(code, "digit")
          click_button "Verify"
          expect(page).to have_content "Agree to the terms and conditions of use"
          click_button "I agree with these terms"
          expect(page).to have_current_path("/authorizations")
          expect(Decidim::User.count).to eq(2)
          user = Decidim::User.last
          expect(user.name).to eq("Unnamed user")
          expect(user.phone_country).to be_nil
          expect(user.phone_number).to be_nil
          expect(user.email).to eq(email)
        end
      end
    end

    context "when the account exists" do
      before do
        allow(SecureRandom).to receive(:random_number).and_return(code)
        fill_in "Email", with: "anotherone@example.org"
        click_button "SEND THE CODE"
        fill_in_code(code, "digit")
        click_button "Verify"
      end

      it "logs in the user and redirects it" do
        expect(page).to have_current_path("/authorizations")
        expect(Decidim::User.count).to eq(1)
        expect(Decidim::User.last).to eq(user)
      end
    end

    context "when changing the default auth_code_length" do
      before do
        allow(Decidim::HalfSignup).to receive(:auth_code_length).and_return(5)
        fill_in "Email", with: email
        click_button "SEND THE CODE"
      end

      it "generates the correct length code and verifies the user" do
        expect(all("input[name^='digit']").count).to eq(5)
      end
    end

    context "when show_tos_page_after_signup is set to false" do
      before do
        allow(SecureRandom).to receive(:random_number).and_return(code)
        allow(Decidim::HalfSignup).to receive(:show_tos_page_after_signup).and_return(false)
        fill_in "Email", with: email
        click_button "SEND THE CODE"
        fill_in_code(code, "digit")
        click_button "Verify"
      end

      it "does not show the agree to the terms page" do
        expect(Decidim::User.count).to eq(2)
        user = Decidim::User.last
        expect(user.name).to eq("Unnamed user")
        expect(page).to have_current_path("/authorizations")
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
