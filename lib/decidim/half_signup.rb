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
    autoload :MenuExtensions, "decidim/half_signup/menu_extensions"
    autoload :GatewayError, "decidim/half_signup/gateway"

    # The country or countries to be selected in country selection
    # during sms verification/authentication. The default is being set to the US.
    config_accessor :default_countries do
      [:us]
    end

    # Configuration to enable or disable agree to the terms and condition pages
    # for new users who create their account. The default is set to true, meaning that
    # new users will be redirected to the agree to the terms and conditions page after creting
    # the account.
    config_accessor :show_tos_page_after_signup do
      true
    end

    # Default configuration digits to generate the auth code.
    config_accessor :auth_code_length do
      4
    end

    # Default configuration to enable or disable the CSRF token verification
    config_accessor :skip_csrf do
      false
    end
  end
end
