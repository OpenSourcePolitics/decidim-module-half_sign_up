# frozen_string_literal: true

module Decidim
  module HalfSignup
    module RegisterationsExtensions
      include Decidim::HalfSignup::PartialSignupSettings

      extend ActiveSupport::Concern

      included do
        def new
          if half_signup_enabled?(current_organization)
            redirect_to decidim_half_signup.users_quick_auth_path
          else
            @form = form(::Decidim::RegistrationForm).from_params(
              user: { sign_up_as: "user" }
            )
            super
          end
        end
      end
    end
  end
end
