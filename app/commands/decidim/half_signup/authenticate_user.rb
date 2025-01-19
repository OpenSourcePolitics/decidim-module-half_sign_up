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
        transaction do
          user = find_or_create_user!
        end

        Rails.logger.debug { "User authenticate: #{user.inspect}" }
        return broadcast(:ok, user) if user.present? && user.is_a?(Decidim::User)
        return broadcast(:invalid, I18n.t("phone_taken", scope: "decidim.half_signup.quick_auth.authenticate_user")) if user == :phone_number_taken

        broadcast(:invalid, I18n.t("error", scope: "decidim.half_signup.quick_auth.authenticate_user"))
      end

      private

      attr_reader :form, :data

      def validate_code
        return :code_expired unless code_still_valid?

        :code_invalid unless data["code"] == form.verification
      end

      def code_still_valid?
        verification_code_sent_at && verification_code_sent_at > CODE_EXPIRATION_WINDOW.ago
      end

      def verification_code_sent_at
        @verification_code_sent_at ||= data["sent_at"]&.in_time_zone
      end

      def find_or_create_user!
        user = if sms_auth?
                 if session.present? && session[:user_id].present?
                   existing_user = update_decidim_user_phone(session, data)

                   existing_user.presence || find_user_by_phone_country(data)
                 else
                   find_user_by_phone_country(data)
                 end
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

      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug { "Error creating user: #{e.inspect}" }
        :phone_number_taken if e.message.downcase.include?("email")
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

      def update_decidim_user_phone(session, data)
        user = Decidim::User.find(session[:user_id])

        return if check_phone_difference(user)

        session[:has_validated] = true

        user.update!(
          phone_number: data["phone"],
          phone_country: data["country"]
        )
        user
      rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
        Rails.logger.debug { "Error updating user: #{e.inspect}" }
        :phone_number_taken if e.message.downcase.include?("email") || e.message.downcase.include?("phone")
      end

      def check_phone_difference(user)
        user.phone_number.present? && (user.phone_number == data["phone"].to_s && user.phone_country == data["country"])
      end

      def find_user_by_phone_country(data)
        Decidim::User.find_by(
          organization: form.organization,
          phone_number: data["phone"],
          phone_country: data["country"]
        )
      end
    end
  end
end