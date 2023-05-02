# frozen_string_literal: true

module Decidim
  module HalfSignup
    class UpdateUserPhone < Decidim::Command
      def initialize(form:, data:, user:)
        @form = form
        @data = data
        @user = user
      end

      def call
        return broadcast(:invalid, unauthorized) if user.blank?
        return broadcast(:invalid) unless form.valid?

        return broadcast(:invalid, verification_failed) unless validate_code!

        return broadcast(:invalid, cant_be_updated) unless validate_user!

        update_user!
        broadcast(:ok)
      end

      private

      attr_reader :form, :data, :user

      def validate_code!
        return false unless code_still_valid?

        data["code"] == form.verification
      end

      def code_still_valid?
        return false unless verification_code_sent_at

        verification_code_sent_at > 5.minutes.ago
      end

      def verification_code_sent_at
        @verification_code_sent_at ||= data["sent_at"]&.in_time_zone
      end

      def validate_user!
        return false if user.blank?

        registered_user = Decidim::User.find_by(
          phone_number: data["phone"],
          phone_country: data["country"],
          organization: form.organization
        )

        return false if registered_user.present? && registered_user != user

        true
      end

      def update_user!
        user.update!(phone_number: data["phone"], phone_country: data["country"])
      end

      def verification_failed
        I18n.t("error", scope: "decidim.half_signup.quick_auth.authenticate_user")
      end

      def cant_be_updated
        I18n.t("phone_exist", scope: "decidim.half_signup.quick_auth.authenticate_user")
      end

      def unauthorized
        I18n.t("unauthorized", scope: "decidim.half_signup.quick_auth.authenticate_user")
      end
    end
  end
end
