# frozen_string_literal: true

require "decidim/core/test/factories"

FactoryBot.define do
  factory :half_signup_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :half_signup).i18n_name }
    manifest_name { :half_signup }
    participatory_space { create(:participatory_process, :with_steps) }
  end

  factory :auth_setting, class: "Decidim::HalfSignup::AuthSetting" do
    slug { "authentication_settings" }
    organization { create(:organization) }
  end
  # Add engine factories here
end
