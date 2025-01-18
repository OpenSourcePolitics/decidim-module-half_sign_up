# frozen_string_literal: true

module Decidim
  module HalfSignup
    class AuthenticateUser < Decidim::Command
      CODE_EXPIRATION_WINDOW = 5.minutes.freeze

      def initialize(form:, data:)
        @form = form
        @data = data
      end

      def call
        return broadcast(:invalid) unless form.valid?

        case validate_code
        when :code_expired
          return broadcast(:invalid, code_expired_message)
        when :code_invalid
          return broadcast(:invalid, verification_failed_message)
        end

        user = nil
        transaction { user = find_or_create_user! }

        return broadcast(:ok, user) if user.present?

        broadcast(:invalid, default_error_message)
      end

      private

      attr_reader :form, :data

      def validate_code
        return :code_expired unless code_valid_within_window?

        :code_invalid unless data["code"] == form.verification
      end

      def code_valid_within_window?
        verification_code_sent_at && verification_code_sent_at > CODE_EXPIRATION_WINDOW.ago
      end

      def verification_code_sent_at
        @verification_code_sent_at ||= data["sent_at"]&.in_time_zone
      end

      def find_or_create_user!
        return authenticate_with_sms if sms_auth?

        find_or_initialize_user
      end

      def authenticate_with_sms
        existing_user = update_user_phone_from_session || find_user_by_phone_country
        return existing_user if existing_user.present? && existing_user != :already_taken

        find_user_by_phone_country
      end

      def update_user_phone_from_session
        return unless session_present_and_valid?

        user = Decidim::User.find(session[:user_id])
        return if user_has_matching_phone?(user)
        return :already_taken if phone_already_taken?

        session[:has_validated] = true
        user.update(
          phone_number: data["phone"],
          phone_country: data["country"]
        )
        user
      rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
        Rails.logger.warn("Error updating user phone: #{e.message}")
        nil
      end

      def session_present_and_valid?
        data["session"]&.dig(:user_id).present?
      end

      def user_has_matching_phone?(user)
        user.phone_number == data["phone"] && user.phone_country == data["country"]
      end

      def phone_already_taken?
        find_user_by_phone_country.present?
      end

      def find_user_by_phone_country
        Decidim::User.find_by(
          organization: form.organization,
          phone_number: data["phone"],
          phone_country: data["country"]
        )
      end

      def find_or_initialize_user
        user = Decidim::User.find_by(email: data["email"], organization: form.organization)
        return user if user.present?

        create_user
      end

      def create_user
        password = SecureRandom.hex
        Decidim::User.create! do |user|
          user.name = I18n.t("unnamed_user", scope: "decidim.half_signup.quick_auth.authenticate")
          user.nickname = UserBaseEntity.nicknamize("#{user.name}_#{SecureRandom.hex(8)}")
          user.email = data["email"].presence || generate_email
          user.password = password
          user.password_confirmation = password
          user.skip_confirmation!
          user.phone_number = data["phone"]
          user.phone_country = data["country"]
          user.tos_agreement = "1"
          user.organization = form.organization
          user.accepted_tos_version = Time.current unless Decidim::HalfSignup.show_tos_page_after_signup
          user.locale = form.current_locale
        end
      end

      def generate_email
        EmailGenerator.new(form.organization, data["country"], data["phone"]).generate
      end

      def sms_auth?
        data["method"] == "sms"
      end

      # Error messages
      def verification_failed_message
        I18n.t("error", scope: "decidim.half_signup.quick_auth.authenticate_user")
      end

      def code_expired_message
        I18n.t("code_expired", scope: "decidim.half_signup.quick_auth.authenticate_user")
      end

      def default_error_message
        I18n.t("error", scope: "decidim.half_signup.quick_auth.authenticate_user")
      end
    end
  end
end
