# frozen_string_literal: true

require "countries"
require "decidim/half_signup/version"
require "decidim/half_signup/admin"
require "decidim/half_signup/engine"
require "decidim/half_signup/admin_engine"
require_relative "half_signup/quick_auth"
require_relative "half_signup/phone_number_formatter"

module Decidim
  # This namespace holds the logic of the `HalfSignup` component. This component
  # allows users to create half_signup in a participatory space.
  module HalfSignup
    include ActiveSupport::Configurable

    autoload :PartialSignupSettings, "decidim/half_signup/partial_signup_settings"

    # The country or countries to be selected in country selection
    # during sms verification/authentication. The default is being set to nil
    config_accessor :default_countries do
      nil
    end
  end
end
