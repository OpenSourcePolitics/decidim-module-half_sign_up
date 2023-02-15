# frozen_string_literal: true

module Decidim
  module HalfSignup
    module PartialSignupSettings
      def authentication_settings(organization)
        @authentication_settings ||= ::Decidim::HalfSignup::AuthSetting.find_or_create_by!(
          slug: "authentication_settings",
          organization: organization
        )
      end
    end
  end
end
