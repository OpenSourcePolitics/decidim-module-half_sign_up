# frozen_string_literal: true

module Decidim
  module HalfSignup
    class AuthenticateUser < Decidim::Command
      def initialize(form:, data:)
        @form = form
        @data = data
      end

      def call
        return broadcast(:invalid) unless form.valid?
        return broadcast(:invalid, verification_failed) unless validate!

        user = nil
        transaction do
          user = find_or_create_user!
        end

        Rails.logger.debug { "User authenticate: #{user.inspect}" }
        return broadcast(:ok, user) if user.present?

        broadcast(:invalid, I18n.t("error", scope: "decidim.half_signup.quick_auth.authenticate_user"))
      end

      private

      attr_reader :form, :data

      def validate!
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

      def find_or_create_user!
        user = if sms_auth?
                 Decidim::User.find_by(
                   phone_number: data["phone"],
                   phone_country: data["country"],
                   organization: form.organization
                 )
               else
                 Decidim::User.find_by(
                   email: data["email"],
                   organization: form.organization
                 )
               end

        return user if user.present?

        generated_password = SecureRandom.hex
        Decidim::User.create! do |record|
          record.name = I18n.t("unnamed_user", scope: "decidim.half_signup.quick_auth.authenticate")
          record.nickname = UserBaseEntity.nicknamize("#{record.name}_#{SecureRandom.hex(4)}")
          record.email = data["email"].presence || generate_email(data["country"], data["phone"])
          record.password = generated_password
          record.password_confirmation = generated_password

          record.skip_confirmation!

          record.phone_number = data["phone"]
          record.phone_country = data["country"]
          record.tos_agreement = "1"
          record.organization = form.organization
          record.accepted_tos_version = Time.current unless Decidim::HalfSignup.show_tos_page_after_signup
          record.locale = form.current_locale
        end
      end

      def generate_email(country, phone)
        EmailGenerator.new(form.organization, country, phone).generate
      end

      def verification_failed
        I18n.t("error", scope: "decidim.half_signup.quick_auth.authenticate_user")
      end

      def sms_auth?
        data["method"] == "sms"
      end
    end
  end
end
