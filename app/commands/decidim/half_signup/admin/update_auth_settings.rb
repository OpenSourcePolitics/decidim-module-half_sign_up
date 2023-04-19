# frozen_string_literal: true

module Decidim
  module HalfSignup
    module Admin
      # A command with all the business logic for updating the current
      # authentication_settings auth settings to be updated.
      class UpdateAuthSettings < Rectify::Command
        # Public: Initializes the command.
        #
        # authentication_settings - The authentication_settings that will be updated.
        # form - A form object with the params.
        def initialize(auth_settings, form)
          @auth_settings = auth_settings
          @form = form
        end

        def call
          return broadcast(:invalid) if form.invalid?

          update_auth_settings
          broadcast(:ok)
        end

        private

        attr_reader :form

        def update_auth_settings
          Decidim.traceability.update!(
            @auth_settings,
            form.current_user,
            attributes
          )
        end

        def attributes
          {
            enable_partial_sms_signup: form.enable_partial_sms_signup,
            enable_partial_email_signup: form.enable_partial_email_signup
          }
        end
      end
    end
  end
end
